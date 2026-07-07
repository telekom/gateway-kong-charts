<!--
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Valkey Recommendations

## Recommended Valkey version

The Gateway Helm chart does not pin or bundle a Valkey/Redis version — Valkey is treated as
external infrastructure that should be set up separately. What the gateway requires is
only standard Valkey/Redis commands over RESP (`INCR`, `EXPIRE`, `EXPIREAT`, `EXISTS`, `INCRBY`,
`EVAL`, `AUTH`, `SELECT`). No Valkey modules, no streams, no cluster-only features.

**Recommended version:** 9.0.x stable.

## Deployment architecture / topology

The rate-limiting clients connect to a single host/port, so Valkey must be exposed
as a **standalone** or **HA-primary** endpoint — **not** Valkey Cluster.

Each counter is tied to a specific route, service, and consumer, so multiple
gateways pointing at the same Valkey will aggregate their counters correctly.
Sharing one Valkey across zones would therefore work technically — but **we still
recommend one Valkey per zone/environment**, for the following reasons:

- **Low latency:** counters are updated in real time on every request, so Valkey
  should be close to the gateway.
- **Failure isolation:** a Valkey outage in one zone cannot affect any other zone.
- **Data residency:** each zone's traffic data stays within that zone.
- **Consistency:** it matches the existing per-zone deployment model.

## Capacity & sizing

### RAM

Valkey stores only the live rate-limiting counters, which are tiny and expire by
themselves — so even a large API estate needs only tens of megabytes, and request
traffic does not grow that number.

Each counter is one small entry that answers the question "who is being limited,
and for which time window":

| route + service + consumer + time-window + period → a single number |
| --- |

**Takeaway:** Valkey is sized purely on the **number of active counters**, never on
the number of configured APIs, consumers, or credentials.

Two properties make this very cheap:

- **Small:** each counter is about 200–300 bytes, including Valkey's internal overhead.
- **Self-expiring:** when a time window ends, its counter is automatically deleted.
  There is no cleanup to manage and no unbounded growth.

#### Example: 1,000 APIs

Assuming each API enforces 2 windows (for example, per-minute and per-hour):

- **Service-level limiting only** → 1,000 APIs × 2 windows = **2,000 counters → under 1 MB**
- **Per-consumer limiting**, with 50 active consumers per API → 1,000 APIs × 2 windows × 51 = **100,000 counters → roughly 25–50 MB**

**Sizing rule of thumb:**

```text
counters ≈ APIs * periods * (1 + active consumers per API)
memory   ≈ counters * ~250 bytes
```

### CPU

Negligible. Each request triggers a single small increment. One modest CPU core
sustains very high request rates, so CPU is not a limiting factor for this workload.

### Recommended limits and thresholds

| Setting | Recommendation | Reason |
| --- | --- | --- |
| Memory allocation | 1–2 GB per instance | Far above the tens-of-MB working set; leaves generous headroom for growth and memory fragmentation (but calculate and double-check for your API rate-limiting assumptions!) |
| Memory alert | At ~70% usage | Scale before reaching the limit |
| Error alerts | On connection / authentication failures | Detect access or networking problems early |
| High availability | Primary + replica | Resilience without needing persistence |

## Behavior if Valkey is unavailable

By default the gateway is **fail-open**: if Valkey is unreachable, your API traffic
keeps flowing normally — only the rate-limit enforcement is temporarily skipped, not
the API requests themselves.

## Onboarding / exposure

Once Valkey is reachable from the gateway, rate limiting works automatically for any
 route/service where the `rate-limiting-merged` plugin is enabled — no additional Valkey-side
 setup is required beyond configuring the plugin.

## Valkey Sentinel

Valkey Sentinel is **not currently supported**. The rate-limiting plugin is designed
to talk to a single Valkey endpoint and cannot perform the Sentinel-based primary
discovery that a Sentinel setup requires.
