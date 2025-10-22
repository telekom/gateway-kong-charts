# Implementation Plan: KEDA-Based Autoscaling for Gateway

**Branch**: `001-adding-keda-i` | **Date**: 2025-10-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-adding-keda-i/spec.md`

## Summary

Add KEDA-based autoscaling to the Gateway Kong Helm chart to enable cost-effective, metric-driven scaling based on CPU, memory, request rate (from Victoria Metrics), and time-based schedules. This replaces the existing basic HPA with a more sophisticated autoscaling solution that supports multiple triggers, custom metrics, and anti-flapping protection.

**Technical Approach**:

- Create new KEDA ScaledObject template that conditionally replaces HPA when enabled
- Extend values.yaml with comprehensive KEDA configuration structure
- Support CPU/memory resource metrics, Prometheus/Victoria Metrics custom metrics, and cron-based schedules
- Implement anti-flapping through KEDA's cooldown periods and stabilization windows
- Maintain backward compatibility by keeping HPA as default, KEDA as opt-in feature

## Technical Context

**Language/Version**: Helm 3.x, Kubernetes 1.21+, KEDA 2.x  
**Primary Dependencies**: KEDA (external), Victoria Metrics (external), Kubernetes Metrics Server  
**Storage**: N/A (configuration only)  
**Testing**: `helm lint`, `helm template`, manual deployment testing with load generation  
**Target Platform**: Kubernetes (all supported platforms: kubernetes, aws, caas)  
**Project Type**: Helm Chart (declarative infrastructure)  
**Performance Goals**: Scale-up within 2 minutes, scale-down within 5 minutes (configurable), <500ms p95 latency during scaling  
**Constraints**: KEDA must be pre-installed, Victoria Metrics must be accessible, backward compatible with existing HPA deployments  
**Scale/Scope**: Single Helm chart modification, ~5 new configuration sections in values.yaml, 1 new template file, updates to existing HPA template

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

Verify compliance with `.specify/memory/constitution.md` principles:

- [x] **Values-First Configuration**: All KEDA configuration exposed in `values.yaml` with defaults and comprehensive inline documentation
- [x] **Template Simplicity**: New ScaledObject template follows single-responsibility pattern, uses named templates for complex logic
- [x] **Backward Compatibility**: KEDA disabled by default, existing HPA remains functional, no breaking changes (MINOR version bump)
- [x] **Platform Portability**: No platform-specific assumptions, works on all supported platforms (kubernetes, aws, caas)
- [x] **Progressive Disclosure**: KEDA feature disabled by default (`kedaAutoscaling.enabled: false`), advanced features clearly grouped
- [x] **Observability**: Scaling events observable through KEDA metrics and Kubernetes events, no impact on existing health probes
- [x] **Security by Default**: Victoria Metrics auth configured with basic auth, no secrets hardcoded, uses existing secret management
- [x] **Helm Best Practices**: Standard labels applied, validation using `required` for critical fields, `fail` for configuration conflicts
- [x] **Testing**: All changes validated with `helm lint`, `helm template`, and test cluster deployment
- [x] **Documentation**: README updated with KEDA section, values.yaml fully documented, CHANGELOG entry for new feature

## Project Structure

### Documentation (this feature)

```
specs/001-adding-keda-i/
├── plan.md              # This file
├── spec.md              # Feature specification (completed)
├── checklists/
│   └── requirements.md  # Quality checklist (completed)
├── research.md          # KEDA scalers research (to be created)
├── data-model.md        # Configuration structure (to be created)
├── quickstart.md        # Usage guide (to be created)
└── contracts/           # KEDA ScaledObject examples (to be created)
```

### Source Code (repository root)

```
gateway-kong-charts/
├── Chart.yaml                              # Version bump (MINOR)
├── values.yaml                             # Add kedaAutoscaling section
├── templates/
│   ├── horizontal-pod-autoscaler.yaml      # Update condition to exclude when KEDA enabled
│   ├── scaled-object-keda.yaml             # NEW: KEDA ScaledObject template
│   ├── deployment-kong.yml                 # Update replicas condition for KEDA
│   └── _kong.tpl                           # Add KEDA-related named templates if needed
├── README.md                               # Add KEDA autoscaling section
├── CHANGELOG.md                            # Document new feature
└── platforms/
    ├── kubernetes.yaml                     # No changes needed
    ├── aws.yaml                            # No changes needed
    └── caas.yaml                           # No changes needed
```

**Structure Decision**: This is a Helm chart modification following the existing template structure. New KEDA functionality is added as a new template file (`scaled-object-keda.yaml`) following the single-responsibility principle. Configuration is added to `values.yaml` under a new `kedaAutoscaling` section to clearly separate it from the existing `autoscaling` (HPA) configuration. No platform-specific changes are needed as KEDA works uniformly across all platforms.

## Phase 0: Research

### KEDA Scalers Investigation

**Objective**: Understand KEDA scaler configurations for CPU, memory, Prometheus, and Cron triggers.

**Research Tasks**:

1. Document KEDA ScaledObject API structure and required fields
2. Research CPU and memory resource scalers (using Kubernetes metrics server)
3. Research Prometheus scaler configuration for Victoria Metrics integration
   - Authentication methods (basic auth)
   - Query format and requirements
   - Threshold configuration
4. Research Cron scaler for time-based scaling
   - Cron expression format
   - Timezone handling (UTC default)
   - Desired replica count configuration
5. Document KEDA cooldown periods and stabilization windows
6. Research KEDA behavior with multiple triggers (OR vs AND logic)
7. Document KEDA conflict resolution with HPA

**Output**: `research.md` with:

- KEDA ScaledObject YAML structure examples
- Each scaler type documented with configuration options
- Victoria Metrics connection requirements
- Anti-flapping configuration options
- Best practices for multi-trigger scenarios

### Existing Chart Analysis

**Objective**: Understand current HPA implementation and integration points.

**Analysis Tasks**:

1. Review `horizontal-pod-autoscaler.yaml` template structure
2. Identify how `autoscaling.enabled` flag controls HPA creation
3. Review how `deployment-kong.yml` handles replicas when autoscaling is enabled
4. Document existing autoscaling values structure
5. Identify any platform-specific autoscaling configurations

**Output**: Document current state in `research.md` including:

- Current HPA configuration options
- Deployment replica management logic
- Integration points for KEDA

## Phase 1: Design

### Configuration Data Model

**Objective**: Design the `kedaAutoscaling` values.yaml structure.

**Design Considerations**:

- Clear separation from existing `autoscaling` (HPA) configuration
- Hierarchical structure grouping related settings
- Sensible defaults that prevent aggressive scaling
- Support for multiple triggers of each type
- Validation-friendly structure

**Output**: `data-model.md` with complete values.yaml structure:

```yaml
kedaAutoscaling:
  enabled: false # Feature flag

  # Replica boundaries
  minReplicas: 2
  maxReplicas: 10

  # Cooldown periods (anti-flapping)
  cooldownPeriod: 300 # seconds (5 minutes)
  pollingInterval: 30 # seconds

  # Fallback when all triggers fail
  fallback:
    enabled: true
    replicas: 10

  # Advanced behavior
  advanced:
    restoreToOriginalReplicaCount: false
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
            - type: Percent
              value: 100
              periodSeconds: 60
            - type: Pods
              value: 4
              periodSeconds: 60
          selectPolicy: Max

  # Trigger configurations
  triggers:
    # CPU resource scalers (per-container)
    cpu:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 70 # percentage
        jumper:
          enabled: true
          threshold: 70 # percentage
        issuerService:
          enabled: true
          threshold: 70 # percentage

    # Memory resource scalers (per-container)
    memory:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 85 # percentage
        jumper:
          enabled: true
          threshold: 85 # percentage
        issuerService:
          enabled: true
          threshold: 85 # percentage

    # Prometheus/Victoria Metrics scaler
    prometheus:
      enabled: true
      serverAddress: "" # REQUIRED if enabled: Victoria Metrics URL
      metricName: "kong_request_rate"
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      threshold: "100" # requests per second across all pods
      authModes: "basic" # basic, bearer, or tls
      # Authentication via ClusterTriggerAuthentication
      authentication:
        clusterTriggerAuthenticationName: "eni-keda-vmselect-creds" # Name of ClusterTriggerAuthentication resource

    # Cron-based schedules (array for multiple schedules)
    cron:
      enabled: false
      timezone: "Europe/Berlin" # Automatically handles CET/CEST transitions
      schedules:
        - name: "business-hours-scale-up"
          start: "0 8 * * 1-5" # 8 AM Mon-Fri
          end: "0 18 * * 1-5" # 6 PM Mon-Fri
          desiredReplicas: 10
        - name: "weekend-scale-down"
          start: "0 0 * * 6-7" # Midnight Sat-Sun
          end: "0 23 * * 6-7" # 11 PM Sat-Sun
          desiredReplicas: 5
```

### Template Design

**Objective**: Design the KEDA ScaledObject template structure.

**Design Decisions**:

1. **Conditional Rendering**: ScaledObject only rendered when `kedaAutoscaling.enabled: true`
2. **HPA Exclusion**: Update HPA template condition to: `{{- if and .Values.autoscaling.enabled (not .Values.kedaAutoscaling.enabled) -}}`
3. **Deployment Replicas**: Update deployment to exclude replicas when either autoscaling or kedaAutoscaling is enabled
4. **Validation**: Add `fail` checks for:
   - KEDA and HPA both enabled (conflict)
   - Prometheus trigger enabled but serverAddress empty
   - minReplicas > maxReplicas
5. **Named Templates**: Create helper templates for:
   - Trigger generation (reduce duplication)
   - Label selectors
   - Validation logic

**Output**: `contracts/scaled-object-example.yaml` with annotated KEDA ScaledObject structure

### Quickstart Guide

**Objective**: Document how operators enable and configure KEDA autoscaling.

**Content**:

1. Prerequisites (KEDA installation, Victoria Metrics access)
2. Minimal configuration example (CPU + memory only)
3. Full configuration example (all triggers)
4. Migration from HPA to KEDA
5. Troubleshooting common issues
6. Validation commands

**Output**: `quickstart.md` with step-by-step instructions

## Phase 2: Implementation Tasks

_Note: Detailed tasks will be generated by `/speckit.tasks` command after plan approval_

**High-Level Implementation Phases**:

1. **Setup**: Update Chart.yaml version, create branch structure
2. **Configuration**: Add `kedaAutoscaling` section to values.yaml with full documentation
3. **Templates**:
   - Create `scaled-object-keda.yaml` template
   - Update `horizontal-pod-autoscaler.yaml` exclusion logic
   - Update `deployment-kong.yml` replicas condition
   - Add validation logic and named templates
4. **Documentation**: Update README.md, CHANGELOG.md, create quickstart guide
5. **Testing**: Helm lint, template rendering, test cluster deployment
6. **Validation**: Verify all constitution principles, test backward compatibility

## Risks & Mitigations

| Risk                                     | Impact                                    | Mitigation                                                                     |
| ---------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------ |
| KEDA not installed in target cluster     | Deployment fails                          | Clear documentation in README, validation message suggesting KEDA installation |
| Victoria Metrics unreachable             | Scaling fails, falls back to min replicas | Document fallback behavior, provide health check examples                      |
| HPA and KEDA both enabled                | Conflicting scaling decisions             | Template validation with `fail` function prevents deployment                   |
| Aggressive scaling causes instability    | Pod churn, performance degradation        | Conservative defaults (5min cooldown, stabilization windows), document tuning  |
| Breaking existing deployments            | Users cannot upgrade                      | KEDA disabled by default, HPA remains default, thorough testing                |
| Complex configuration overwhelming users | Misconfiguration, support burden          | Progressive disclosure, sensible defaults, comprehensive examples              |

## Success Metrics

Aligned with spec.md Success Criteria:

- **SC-001**: Scale-up within 2 minutes verified through load testing
- **SC-002**: Scale-down within cooldown period (5 min default) verified
- **SC-003**: Cost reduction measurable through replica count over time
- **SC-004**: p95 latency <500ms during scaling verified with monitoring
- **SC-005**: Anti-flapping effectiveness (max 1 event/5min) verified with oscillating load
- **SC-006**: Schedule transitions within 30 seconds verified
- **SC-007**: Deployment success with documented configuration only
- **SC-008**: Backward compatibility verified with existing deployments
- **SC-009**: Memory-based scaling verified independently of CPU

## Next Steps

1. **Review this plan** with stakeholders
2. **Execute Phase 0 (Research)**: Create `research.md` with KEDA scaler documentation
3. **Execute Phase 1 (Design)**: Create `data-model.md`, `contracts/`, and `quickstart.md`
4. **Generate tasks**: Run `/speckit.tasks` to create detailed implementation task list
5. **Begin implementation**: Follow task list, validate against constitution at each phase
6. **Testing & validation**: Deploy to test cluster, verify all success criteria
7. **Documentation review**: Ensure README and CHANGELOG are complete
8. **Release**: Merge to main, tag new MINOR version

## Open Questions

1. **Victoria Metrics Secret Management**: Should we create a new secret for VM auth or reuse an existing one?
   - _Recommendation_: Allow users to specify existing secret name, document secret format in README
2. **Default Prometheus Query**: Should the default query be more generic or zone-specific?
   - _Recommendation_: Make it zone-specific by default (uses `.Values.global.zone`), document how to customize
3. **KEDA Version Compatibility**: What minimum KEDA version should we support?
   - _Recommendation_: KEDA 2.10+ (stable Prometheus scaler with auth support)
4. **Cron Timezone**: Should we support per-schedule timezones or global only?
   - _Recommendation_: Global timezone for simplicity, document in values.yaml
5. **Migration Strategy**: Should we provide a migration tool/script from HPA to KEDA?
   - _Recommendation_: Document manual migration steps in quickstart.md, no automated tool needed for initial release
