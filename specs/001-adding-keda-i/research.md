# Research: KEDA Autoscaling Implementation

**Date**: 2025-10-14  
**Feature**: KEDA-Based Autoscaling for Gateway  
**Purpose**: Document KEDA scaler types, configuration options, and integration requirements

## KEDA Overview

KEDA (Kubernetes Event-Driven Autoscaling) extends Kubernetes autoscaling capabilities by supporting event-driven and custom metric scaling. It creates and manages HPA resources internally based on ScaledObject definitions.

**Key Concepts**:

- **ScaledObject**: Custom resource defining scaling behavior and triggers
- **Scalers**: Plugins that connect to external metric sources
- **Triggers**: Individual scaling rules within a ScaledObject
- **Cooldown Period**: Time to wait after last trigger activation before scaling down
- **Polling Interval**: How often KEDA checks metrics

## KEDA ScaledObject Structure

### Basic Structure

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: gateway-scaledobject
  namespace: default
spec:
  scaleTargetRef:
    name: deployment-name
  minReplicaCount: 2
  maxReplicaCount: 10
  pollingInterval: 30 # seconds
  cooldownPeriod: 300 # seconds (5 minutes)

  # Advanced HPA behavior configuration
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

  # Fallback configuration
  fallback:
    failureThreshold: 3
    replicas: 10

  # Triggers (multiple allowed)
  triggers:
    - type: cpu
      metricType: Utilization
      metadata:
        value: "70"

    - type: memory
      metricType: Utilization
      metadata:
        value: "85"

    - type: prometheus
      metadata:
        serverAddress: http://victoria-metrics:8428
        metricName: kong_request_rate
        query: sum(rate(kong_http_requests_total[1m]))
        threshold: "100"
        authModes: "basic"
      authenticationRef:
        name: eni-keda-vmselect-creds
        kind: ClusterTriggerAuthentication

    - type: cron
      metadata:
        timezone: Europe/Berlin
        start: 0 8 * * 1-5
        end: 0 18 * * 1-5
        desiredReplicas: "10"
```

## Scaler Types

### 1. CPU Scaler

**Purpose**: Scale based on CPU utilization percentage

**Configuration**:

```yaml
triggers:
  - type: cpu
    metricType: Utilization # or AverageValue
    metadata:
      value: "70" # 70% CPU utilization
```

**Behavior**:

- Uses Kubernetes metrics server
- Calculates average CPU across all pods
- Triggers scale-up when average exceeds threshold
- Triggers scale-down when average falls below threshold (with cooldown)

**Best Practices**:

- Set threshold between 60-80% for headroom
- Consider CPU request values when setting thresholds
- Combine with memory scaler for comprehensive resource monitoring

### 2. Memory Scaler

**Purpose**: Scale based on memory utilization percentage

**Configuration**:

```yaml
triggers:
  - type: memory
    metricType: Utilization # or AverageValue
    metadata:
      value: "85" # 85% memory utilization
```

**Behavior**:

- Uses Kubernetes metrics server
- Calculates average memory across all pods
- Memory-based scaling often needs higher thresholds than CPU (80-90%)
- Important for memory-intensive workloads

**Best Practices**:

- Set threshold higher than CPU (80-90%) since memory is less elastic
- Ensure memory requests are properly configured
- Monitor for memory leaks that could cause continuous scaling

### 3. Prometheus Scaler

**Purpose**: Scale based on custom metrics from Prometheus-compatible systems (Victoria Metrics)

**Configuration**:

```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: http://victoria-metrics.monitoring:8428
      metricName: kong_request_rate
      query: |
        sum(rate(kong_http_requests_total{tardis_telekom_de_zone="zone1"}[1m]))
      threshold: "100"
      activationThreshold: "50" # Optional: minimum value to activate scaler
      authModes: "basic" # basic, bearer, or tls
    authenticationRef:
      name: eni-keda-vmselect-creds # ClusterTriggerAuthentication resource name
      kind: ClusterTriggerAuthentication
```

**Authentication Configuration**:

KEDA requires a ClusterTriggerAuthentication resource for Prometheus auth. This is a cluster-scoped resource that can be shared across namespaces:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ClusterTriggerAuthentication
metadata:
  name: eni-keda-vmselect-creds
spec:
  secretTargetRef:
    - parameter: username
      name: victoria-metrics-secret
      key: username
      namespace: monitoring # Namespace where the secret exists
    - parameter: password
      name: victoria-metrics-secret
      key: password
      namespace: monitoring
```

**Note**: ClusterTriggerAuthentication is preferred over namespace-scoped TriggerAuthentication because:

- It can be shared across multiple namespaces
- Cluster administrators can manage credentials centrally
- Applications don't need to create their own authentication resources

**Query Requirements**:

- Must return a single numeric value
- Use aggregation functions (sum, avg, max, etc.)
- Include appropriate time windows (e.g., `[1m]`, `[5m]`)
- Filter by relevant labels (zone, namespace, etc.)

**Victoria Metrics Specifics**:

- Compatible with Prometheus query language (PromQL)
- Endpoint typically: `http://<vmauth-url>/select/0/prometheus`
- Supports basic auth via VMAUTH_RACCOON_INGRESS_URL
- Query format identical to Prometheus

**Example Queries**:

```promql
# Request rate per pod
sum(rate(kong_http_requests_total{tardis_telekom_de_zone="zone1"}[1m])) / count(kong_http_requests_total{tardis_telekom_de_zone="zone1"})

# Total request rate across all pods
sum(rate(kong_http_requests_total{tardis_telekom_de_zone="zone1"}[1m]))

# Error rate percentage
sum(rate(kong_http_requests_total{status=~"5.."}[1m])) / sum(rate(kong_http_requests_total[1m])) * 100

# Active connections
sum(kong_nginx_connections_active{tardis_telekom_de_zone="zone1"})
```

**Best Practices**:

- Use rate() for counter metrics
- Include appropriate time windows (1m for responsive scaling, 5m for stability)
- Test queries in Victoria Metrics UI before deploying
- Set activationThreshold to prevent scaling from 0 unnecessarily
- Use zone-specific labels to isolate metrics

### 4. Cron Scaler

**Purpose**: Scale based on time schedules (predictable traffic patterns)

**Configuration**:

```yaml
triggers:
  - type: cron
    metadata:
      timezone: Europe/Berlin
      start: 0 8 * * 1-5 # 8 AM Monday-Friday (CET/CEST)
      end: 0 18 * * 1-5 # 6 PM Monday-Friday (CET/CEST)
      desiredReplicas: "10"

  - type: cron
    metadata:
      timezone: Europe/Berlin
      start: 0 0 * * 6-7 # Midnight Saturday-Sunday (CET/CEST)
      end: 0 23 * * 6-7 # 11 PM Saturday-Sunday (CET/CEST)
      desiredReplicas: "5"
```

**Cron Expression Format**:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

**Examples**:

- `0 8 * * 1-5`: 8 AM Monday-Friday
- `0 18 * * *`: 6 PM every day
- `*/15 * * * *`: Every 15 minutes
- `0 0 * * 0`: Midnight every Sunday

**Behavior**:

- Sets minimum replica count during active window
- Other triggers can still scale above the cron-defined minimum
- Multiple cron triggers can overlap (highest desiredReplicas wins)
- Transitions happen at exact cron time (within polling interval)

**Timezone Handling**:

- Use IANA timezone database names (e.g., "Europe/Berlin", "America/New_York")
- KEDA automatically handles Daylight Saving Time (DST) transitions
- "Europe/Berlin" handles CET (UTC+1 winter) and CEST (UTC+2 summer) automatically
- Avoid using "CET" or "CEST" directly - use location-based names instead
- See full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

**Best Practices**:

- Use location-based timezones for automatic DST handling
- Ensure start/end times don't create gaps
- Set desiredReplicas as minimum, allow metric triggers to scale higher
- Test cron expressions using online validators
- Document business hour patterns in values.yaml comments

## Multi-Trigger Behavior

### Trigger Logic

KEDA evaluates all triggers and uses **OR logic**:

- If ANY trigger suggests scaling up → scale up
- If ALL triggers suggest scaling down → scale down (after cooldown)
- This prioritizes availability over cost savings

### Example Scenario

Configuration:

- CPU thresholds: 70% (per-container: kong, jumper, issuerService)
- Memory thresholds: 85% (per-container: kong, jumper, issuerService)
- Request rate threshold: 100 req/s
- Cron: 5 replicas during business hours

Behavior:

1. **Business hours, low load**: Cron sets minimum to 5 replicas
2. **Business hours, high kong CPU (80%)**: Scales above 5 based on kong container CPU
3. **Business hours, high jumper memory (90%), low CPU (50%)**: Scales based on jumper container memory
4. **Off-hours, low load**: Scales down to minReplicas (e.g., 2)
5. **Off-hours, traffic spike**: Scales up based on request rate despite off-hours
6. **Any container exceeds threshold**: Triggers scaling even if other containers are below their thresholds

### Stabilization Windows

**Scale-Up Stabilization**:

- Default: 0 seconds (immediate scale-up for availability)
- Can be configured to prevent rapid scale-up on brief spikes

**Scale-Down Stabilization**:

- Default: 300 seconds (5 minutes)
- Prevents rapid scale-down on brief load drops
- Configurable per use case

**Configuration**:

```yaml
advanced:
  horizontalPodAutoscalerConfig:
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
        policies:
          - type: Percent
            value: 10 # Max 10% reduction per period
            periodSeconds: 60
      scaleUp:
        stabilizationWindowSeconds: 0
        policies:
          - type: Percent
            value: 100 # Max 100% increase per period
            periodSeconds: 60
          - type: Pods
            value: 4 # Or max 4 pods per period
            periodSeconds: 60
        selectPolicy: Max # Use the more aggressive policy
```

## Anti-Flapping Mechanisms

### 1. Cooldown Period

**Purpose**: Minimum time between scale-down actions

**Configuration**:

```yaml
spec:
  cooldownPeriod: 300 # 5 minutes
```

**Behavior**:

- Applies only to scale-down
- After scaling down, KEDA waits cooldownPeriod before scaling down again
- Does not affect scale-up (availability prioritized)

**Recommended Values**:

- Conservative: 300-600 seconds (5-10 minutes)
- Aggressive: 120-180 seconds (2-3 minutes)
- Very stable workloads: 60 seconds (1 minute)

### 2. Polling Interval

**Purpose**: How often KEDA checks metrics

**Configuration**:

```yaml
spec:
  pollingInterval: 30 # seconds
```

**Behavior**:

- Lower values = more responsive but more API calls
- Higher values = less responsive but lower overhead

**Recommended Values**:

- Responsive: 15-30 seconds
- Balanced: 30-60 seconds
- Conservative: 60-120 seconds

### 3. Stabilization Windows

See "Multi-Trigger Behavior" section above.

### 4. Activation Threshold

**Purpose**: Minimum metric value to activate a scaler

**Configuration**:

```yaml
triggers:
  - type: prometheus
    metadata:
      threshold: "100"
      activationThreshold: "50" # Only activate when > 50
```

**Behavior**:

- Prevents scaling from 0 when metric is slightly above 0
- Useful for preventing unnecessary scale-up on minimal load

## KEDA and HPA Conflict Resolution

### The Problem

KEDA creates HPA resources internally. If a manual HPA exists for the same deployment, conflicts occur:

- Both HPAs try to manage the same deployment
- Unpredictable scaling behavior
- Potential for rapid scaling oscillation

### Solution in Helm Chart

**Mutual Exclusion**:

```yaml
# horizontal-pod-autoscaler.yaml
{{- if and .Values.autoscaling.enabled (not .Values.kedaAutoscaling.enabled) -}}
# ... HPA definition
{{- end }}

# scaled-object-keda.yaml
{{- if .Values.kedaAutoscaling.enabled -}}
# ... ScaledObject definition
{{- end }}
```

**Validation**:

```yaml
{{- if and .Values.autoscaling.enabled .Values.kedaAutoscaling.enabled -}}
{{- fail "Cannot enable both autoscaling (HPA) and kedaAutoscaling (KEDA). Please enable only one." -}}
{{- end }}
```

**Deployment Replicas**:

```yaml
# deployment-kong.yml
spec:
{{- if not (or .Values.autoscaling.enabled .Values.kedaAutoscaling.enabled) }}
  replicas: {{ .Values.replicas | default 1 }}
{{- end }}
```

## Integration with Existing Chart

### Current HPA Implementation

**File**: `templates/horizontal-pod-autoscaler.yaml`

```yaml
{{- if .Values.autoscaling.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Release.Name }}-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Release.Name }}
  minReplicas: {{ .Values.autoscaling.minReplicas | default .Values.replicas | default 3 }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas | default 10 }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.cpuUtilizationPercentage | default 80 }}
{{- end }}
```

**Current Values Structure**:

```yaml
autoscaling:
  enabled: false
  minReplicas: 3
  maxReplicas: 10
  cpuUtilizationPercentage: 80
```

### KEDA Integration Points

1. **New Template**: `templates/scaled-object-keda.yaml`
2. **Updated Template**: `templates/horizontal-pod-autoscaler.yaml` (add KEDA exclusion)
3. **Updated Template**: `templates/deployment-kong.yml` (update replicas condition)
4. **New Values Section**: `kedaAutoscaling` in `values.yaml`
5. **Optional**: `templates/trigger-authentication-keda.yaml` for Victoria Metrics auth

### Backward Compatibility Strategy

**Default Behavior** (no changes for existing users):

```yaml
autoscaling:
  enabled: false # Existing HPA disabled by default

kedaAutoscaling:
  enabled: false # New KEDA disabled by default
```

**Migration Path**:

1. User currently using HPA: No changes needed, continues working
2. User wants to try KEDA: Set `kedaAutoscaling.enabled: true`, keep `autoscaling.enabled: false`
3. User wants to switch from HPA to KEDA: Set `autoscaling.enabled: false`, set `kedaAutoscaling.enabled: true`

**No Breaking Changes**:

- Existing `autoscaling` section unchanged
- New `kedaAutoscaling` section added
- Default behavior preserved (no autoscaling)
- Chart version: MINOR bump (new feature, backward compatible)

## Victoria Metrics Integration

### Connection Details

**Server Address**: Provided via values

```yaml
kedaAutoscaling:
  triggers:
    prometheus:
      serverAddress: "{{ .Values.global.vmauth.url }}" # Or hardcoded URL
```

**Authentication**:

- Method: Basic Auth
- Credentials: Stored in Kubernetes Secret
- KEDA accesses via TriggerAuthentication resource

### Secret Structure

**Expected Secret Format**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: victoria-metrics-auth
type: Opaque
stringData:
  username: "your-username"
  password: "your-password"
```

**Chart Configuration**:

```yaml
kedaAutoscaling:
  triggers:
    prometheus:
      authSecret:
        name: "victoria-metrics-auth" # User-provided secret
        usernameKey: "username"
        passwordKey: "password"
```

### Query Configuration

**User-Provided Query**:

```yaml
kedaAutoscaling:
  triggers:
    prometheus:
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      threshold: "100"
```

**Template Rendering**:

- Helm renders the query template with values
- KEDA receives the final query string
- Victoria Metrics executes the query

**Zone-Specific Filtering**:

- Use `{{ .Values.global.zone }}` in query template
- Ensures metrics are scoped to correct zone
- Prevents cross-zone scaling interference

## Best Practices Summary

### Configuration

1. **Start Conservative**: High thresholds, long cooldowns, test in non-prod
2. **Progressive Tuning**: Adjust based on observed behavior
3. **Document Decisions**: Comment why specific thresholds were chosen
4. **Zone Awareness**: Always filter metrics by zone in multi-zone deployments

### Scaling Behavior

1. **Prioritize Availability**: Fast scale-up (0s stabilization), slow scale-down (5min cooldown)
2. **Combine Triggers**: Use CPU + memory + custom metrics for comprehensive coverage
3. **Use Cron for Predictable Patterns**: Pre-scale before known traffic increases
4. **Set Realistic Thresholds**: 70% CPU, 85% memory, test with actual load

### Monitoring

1. **Watch KEDA Metrics**: Monitor scaler activity and errors
2. **Track Scaling Events**: Use Kubernetes events to understand scaling decisions
3. **Measure Impact**: Compare costs and performance before/after KEDA
4. **Alert on Issues**: Alert when scaling fails or metrics are unavailable

### Security

1. **Secure Credentials**: Use Kubernetes Secrets, never hardcode
2. **Least Privilege**: Victoria Metrics credentials should have read-only access
3. **Network Policies**: Restrict KEDA's access to metrics sources
4. **Audit Queries**: Review Prometheus queries for injection risks

## References

- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Prometheus Scaler](https://keda.sh/docs/scalers/prometheus/)
- [Cron Scaler](https://keda.sh/docs/scalers/cron/)
- [CPU/Memory Scalers](https://keda.sh/docs/scalers/cpu/)
- [Victoria Metrics PromQL](https://docs.victoriametrics.com/MetricsQL.html)
- [Kubernetes HPA Behavior](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)
