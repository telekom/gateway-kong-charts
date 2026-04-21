<!--
SPDX-FileCopyrightText: 2026 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# StarGate Pod Shutdown Lifecycle

This document explains how a StarGate pod shuts down gracefully during a rolling update or explicit deletion.

## Goals

1. Stop receiving new traffic before any container begins shutting down (EndpointSlice propagation).
2. Drain in-flight requests already accepted by Kong before the process exits.
3. Allow Jumper's Spring graceful shutdown to complete active HTTP connections.
4. Prevent Kong forwarding requests to Jumper when it is already shutting down.

## How Kubernetes Terminates a Pod

When a pod is deleted, Kubernetes does the following **in parallel** for every container:

1. Runs the `preStop` hook (if defined).
2. After the hook completes, sends **SIGTERM** to PID 1 of the container.
3. After `terminationGracePeriodSeconds` from the moment of deletion, sends **SIGKILL** if the process is still running.

The `terminationGracePeriodSeconds` countdown starts at pod deletion time — it is **not** reset after the preStop hook finishes. The preStop hook time counts against the total budget.

At the same time, the EndpointSlice controller begins removing the pod from service endpoints. This propagation is eventually consistent and typically takes a few seconds under normal cluster load.

## Container Behaviour

### kong

Kong runs with `KONG_NGINX_DAEMON=off`, making it PID 1. This means:

- **SIGTERM** triggers a **fast shutdown** — the nginx master exits immediately without waiting for in-flight requests to complete.
- To drain in-flight requests, `kong quit --timeout <N>` must be called **before** SIGTERM arrives, i.e. inside the preStop hook.

The preStop hook for kong therefore does two things in sequence:

```
sleep 15s   →   kong quit --timeout 60s
```

The sleep covers EndpointSlice propagation. Once `kong quit` completes, Kong has already exited cleanly. When SIGTERM subsequently arrives, the process is gone and there is nothing left to kill.

### jumper

Jumper is a Spring Boot application configured with:

```yaml
server:
  shutdown: GRACEFUL
spring:
  lifecycle:
    timeout-per-shutdown-phase: 1m
```

Spring graceful shutdown is triggered by **SIGTERM**, not by the preStop hook. When SIGTERM arrives, Spring stops accepting new requests and waits for in-flight requests to finish (up to 60 seconds per phase).

The preStop hook for jumper is a plain sleep:

```
sleep 16s
```

**Why 16s and not 15s?** The extra second ensures jumper's preStop hook outlasts kong's sleep, so Kong stops accepting new connections slightly before Jumper does. This prevents a race where Jumper shuts down first and Kong is left forwarding requests to a Jumper that is no longer accepting them.

### issuer-service

Same pattern as jumper — preStop sleep of 16 seconds, then normal process shutdown on SIGTERM.

## Timing Diagram

```
t=0s   Pod deletion triggered
       │
       ├─► EndpointSlice controller removes pod from endpoints
       │     └─► kube-proxy/LB propagation (~2–10s) ──► no new traffic reaches pod
       │
       ├─► kong      preStop: sleep 15s
       │                              └─► kong quit --timeout 60s ──► kong exits cleanly
       │                                                          └─► SIGTERM (no-op)
       │
       ├─► jumper    preStop: sleep 16s
       │                               └─► SIGTERM ──► Spring graceful shutdown (up to 60s)
       │                                                └─► jumper exits
       │
       └─► issuer    preStop: sleep 16s
                                       └─► SIGTERM ──► normal shutdown
                                                        └─► issuer exits

       0─────────────15──16────────────────────────────────────75──76──► t (seconds)
                      │   │                                     │   │
                      │   └── SIGTERM → jumper, issuer          │   └── jumper worst case
                      └── kong quit starts                      └── kong worst case

       terminationGracePeriodSeconds: ≥ 76s recommended (critical path = 70s)
       SIGKILL fires at terminationGracePeriodSeconds if any container still running
```

## Budget Summary

| Phase | Duration | Cumulative |
|---|---|---|
| preStop sleep (kong) | 15s | 15s |
| `kong quit --timeout` | up to 60s | up to 75s |
| preStop sleep (jumper / issuer) | 16s | 16s |
| Spring graceful shutdown (jumper) | up to 60s | up to 76s |
| `terminationGracePeriodSeconds` | ≥ 76s (recommended) | — |

The grace period must be long enough to cover the longest container's total shutdown time. Kong's path (`15s sleep + 60s drain = 75s`) is the critical path. A `terminationGracePeriodSeconds` of **76–90s** provides a reasonable buffer.
