# Data Model: KEDA Autoscaling Configuration

**Date**: 2025-10-14  
**Feature**: KEDA-Based Autoscaling for Gateway  
**Purpose**: Define the complete values.yaml structure for KEDA configuration

## Overview

This document defines the `kedaAutoscaling` section to be added to `values.yaml`. The structure follows Helm chart best practices with hierarchical organization, sensible defaults, and comprehensive inline documentation.

## Complete values.yaml Structure

```yaml
# ============================================================================
# KEDA-Based Autoscaling Configuration
# ============================================================================
# KEDA (Kubernetes Event-Driven Autoscaling) provides advanced autoscaling
# capabilities including custom metrics, schedule-based scaling, and
# sophisticated anti-flapping protection.
#
# Prerequisites:
# - KEDA must be installed in the cluster (helm install keda kedacore/keda)
# - Victoria Metrics must be accessible for custom metric scaling
# - Kubernetes metrics server must be running for CPU/memory scaling
#
# Note: kedaAutoscaling and autoscaling (HPA) are mutually exclusive.
# Enable only one at a time.
# ============================================================================

kedaAutoscaling:
  # -- Enable KEDA-based autoscaling (disables standard HPA if enabled)
  enabled: false
  
  # ============================================================================
  # Replica Boundaries
  # ============================================================================
  
  # -- Minimum number of replicas (must be >= 1)
  minReplicas: 2
  
  # -- Maximum number of replicas (must be >= minReplicas)
  maxReplicas: 10
  
  # ============================================================================
  # Timing Configuration (Anti-Flapping)
  # ============================================================================
  
  # -- Polling interval in seconds (how often KEDA checks metrics)
  # Lower values = more responsive but more API calls
  # Recommended: 30-60 seconds for balanced behavior
  pollingInterval: 30
  
  # -- Cooldown period in seconds (minimum time between scale-down actions)
  # Prevents rapid scale-down oscillations
  # Recommended: 300 seconds (5 minutes) for stable workloads
  cooldownPeriod: 300
  
  # ============================================================================
  # Fallback Configuration
  # ============================================================================
  # Defines behavior when all scaling triggers fail (e.g., metrics unavailable)
  
  fallback:
    # -- Enable fallback to a fixed replica count when all triggers fail
    enabled: true
    
    # -- Number of replicas to maintain when all triggers fail
    replicas: 3
  
  # ============================================================================
  # Advanced HPA Behavior Configuration
  # ============================================================================
  # Fine-tune scaling behavior using Kubernetes HPA v2 behavior policies
  
  advanced:
    # -- Restore to original replica count when ScaledObject is deleted
    restoreToOriginalReplicaCount: false
    
    # -- HPA behavior configuration (scale-up/scale-down policies)
    horizontalPodAutoscalerConfig:
      behavior:
        # Scale-down behavior (conservative to prevent flapping)
        scaleDown:
          # -- Stabilization window for scale-down (seconds)
          # KEDA waits this long before scaling down to ensure load is sustained
          stabilizationWindowSeconds: 300
          
          # -- Scale-down policies (multiple policies can be defined)
          policies:
          - type: Percent
            value: 10        # Max 10% reduction per period
            periodSeconds: 60
          
          # -- Policy selection (Min = most conservative, Max = most aggressive)
          selectPolicy: Min
        
        # Scale-up behavior (aggressive for availability)
        scaleUp:
          # -- Stabilization window for scale-up (seconds)
          # 0 = immediate scale-up for availability
          stabilizationWindowSeconds: 0
          
          # -- Scale-up policies
          policies:
          - type: Percent
            value: 100       # Max 100% increase per period
            periodSeconds: 60
          - type: Pods
            value: 4         # Or max 4 pods per period
            periodSeconds: 60
          
          # -- Policy selection (Max = use most aggressive policy)
          selectPolicy: Max
  
  # ============================================================================
  # Scaling Triggers
  # ============================================================================
  # Multiple triggers can be enabled simultaneously (OR logic)
  # If ANY trigger suggests scale-up → scale up
  # If ALL triggers suggest scale-down → scale down (after cooldown)
  
  triggers:
    
    # ==========================================================================
    # CPU Resource Scalers (Per-Container)
    # ==========================================================================
    # Scales based on CPU utilization percentage for individual containers
    # Requires: Kubernetes metrics server
    # Multiple containers can be monitored independently
    
    cpu:
      # -- Enable CPU-based scaling for any container
      enabled: true
      
      # -- Per-container CPU thresholds
      # Each container in the pod can have its own threshold
      # If ANY container exceeds its threshold, scaling is triggered
      containers:
        # Kong container (main API gateway)
        kong:
          # -- Enable CPU monitoring for kong container
          enabled: true
          # -- CPU utilization threshold percentage (0-100)
          # Recommended: 60-80% for headroom
          threshold: 70
        
        # Jumper container (JWT validation service)
        jumper:
          # -- Enable CPU monitoring for jumper container
          enabled: true
          # -- CPU utilization threshold percentage (0-100)
          threshold: 70
        
        # Issuer Service container (certificate issuer)
        issuerService:
          # -- Enable CPU monitoring for issuer-service container
          enabled: true
          # -- CPU utilization threshold percentage (0-100)
          threshold: 70
    
    # ==========================================================================
    # Memory Resource Scalers (Per-Container)
    # ==========================================================================
    # Scales based on memory utilization percentage for individual containers
    # Requires: Kubernetes metrics server
    # Multiple containers can be monitored independently
    
    memory:
      # -- Enable memory-based scaling for any container
      enabled: true
      
      # -- Per-container memory thresholds
      # Each container in the pod can have its own threshold
      # If ANY container exceeds its threshold, scaling is triggered
      containers:
        # Kong container (main API gateway)
        kong:
          # -- Enable memory monitoring for kong container
          enabled: true
          # -- Memory utilization threshold percentage (0-100)
          # Recommended: 80-90% (higher than CPU due to less elasticity)
          threshold: 85
        
        # Jumper container (JWT validation service)
        jumper:
          # -- Enable memory monitoring for jumper container
          enabled: true
          # -- Memory utilization threshold percentage (0-100)
          threshold: 85
        
        # Issuer Service container (certificate issuer)
        issuerService:
          # -- Enable memory monitoring for issuer-service container
          enabled: true
          # -- Memory utilization threshold percentage (0-100)
          threshold: 85
    
    # ==========================================================================
    # Prometheus/Victoria Metrics Scaler
    # ==========================================================================
    # Scales based on custom metrics from Victoria Metrics
    # Requires: Victoria Metrics accessible, authentication configured
    
    prometheus:
      # -- Enable Prometheus/Victoria Metrics based scaling
      enabled: true
      
      # -- Victoria Metrics server address (REQUIRED if enabled)
      # Example: "http://vmauth-raccoon.monitoring.svc.cluster.local:8427"
      # Can use template variables: "{{ .Values.global.vmauth.url }}"
      serverAddress: ""
      
      # -- Metric name (used for identification in KEDA)
      metricName: "kong_request_rate"
      
      # -- PromQL query to execute
      # Must return a single numeric value
      # Can use Helm template variables (e.g., {{ .Values.global.zone }})
      # Example queries:
      #   - Request rate: sum(rate(kong_http_requests_total{zone="zone1"}[1m]))
      #   - Per-pod rate: sum(rate(kong_http_requests_total[1m])) / count(up{job="kong"})
      #   - Error rate: sum(rate(kong_http_requests_total{status=~"5.."}[1m]))
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      
      # -- Threshold value for the metric
      # Scales up when query result exceeds this value
      # For request rate: total requests/second across all pods
      threshold: "100"
      
      # -- Activation threshold (optional)
      # Minimum metric value to activate this scaler
      # Prevents scaling from 0 on minimal load
      activationThreshold: ""
      
      # -- Authentication mode for Victoria Metrics
      # Options: "basic", "bearer", "tls"
      authModes: "basic"
      
      # -- Authentication configuration
      # Reference to existing ClusterTriggerAuthentication resource
      # ClusterTriggerAuthentication is a cluster-scoped resource that can be shared
      # across namespaces, unlike TriggerAuthentication which is namespace-scoped
      authentication:
        # -- Name of the ClusterTriggerAuthentication resource
        # This resource must be created separately and contain Victoria Metrics credentials
        # Example:
        #   apiVersion: keda.sh/v1alpha1
        #   kind: ClusterTriggerAuthentication
        #   metadata:
        #     name: eni-keda-vmselect-creds
        #   spec:
        #     secretTargetRef:
        #     - parameter: username
        #       name: victoria-metrics-secret
        #       key: username
        #     - parameter: password
        #       name: victoria-metrics-secret
        #       key: password
        clusterTriggerAuthenticationName: "eni-keda-vmselect-creds"
    
    # ==========================================================================
    # Cron-Based Scalers
    # ==========================================================================
    # Scales based on time schedules (predictable traffic patterns)
    # Multiple schedules can be defined for different time windows
    
    cron:
      # -- Enable cron-based (schedule) scaling
      enabled: false
      
      # -- Timezone for cron schedules
      # Use IANA timezone database names for automatic DST handling
      # Europe/Berlin automatically handles CET (UTC+1) and CEST (UTC+2) transitions
      # Format: IANA timezone (e.g., "Europe/Berlin", "America/New_York", "Asia/Tokyo")
      # See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
      timezone: "Europe/Berlin"
      
      # -- List of cron schedules
      # Each schedule defines a time window and desired replica count
      # Multiple schedules can overlap (highest desiredReplicas wins)
      schedules: []
      # Example schedules:
      # - name: "business-hours-scale-up"
      #   start: "0 8 * * 1-5"      # 8 AM Monday-Friday
      #   end: "0 18 * * 1-5"       # 6 PM Monday-Friday
      #   desiredReplicas: 5
      # 
      # - name: "weekend-scale-down"
      #   start: "0 0 * * 6-7"      # Midnight Saturday-Sunday
      #   end: "0 23 * * 6-7"       # 11 PM Saturday-Sunday
      #   desiredReplicas: 2
      #
      # - name: "night-scale-down"
      #   start: "0 22 * * *"       # 10 PM every day
      #   end: "0 6 * * *"          # 6 AM every day
      #   desiredReplicas: 2
      #
      # Cron expression format:
      # ┌───────────── minute (0 - 59)
      # │ ┌───────────── hour (0 - 23)
      # │ │ ┌───────────── day of month (1 - 31)
      # │ │ │ ┌───────────── month (1 - 12)
      # │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
      # │ │ │ │ │
      # * * * * *
```

## Configuration Examples

### Example 1: Minimal Configuration (CPU + Memory Only)

```yaml
kedaAutoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  
  triggers:
    cpu:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 70
        jumper:
          enabled: true
          threshold: 70
        issuerService:
          enabled: true
          threshold: 70
    
    memory:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 85
        jumper:
          enabled: true
          threshold: 85
        issuerService:
          enabled: true
          threshold: 85
    
    prometheus:
      enabled: false
    
    cron:
      enabled: false
```

### Example 2: Full Configuration (All Triggers)

```yaml
kedaAutoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
  pollingInterval: 30
  cooldownPeriod: 300
  
  fallback:
    enabled: true
    replicas: 3
  
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
  
  triggers:
    cpu:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 70
        jumper:
          enabled: true
          threshold: 70
        issuerService:
          enabled: true
          threshold: 70
    
    memory:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 85
        jumper:
          enabled: true
          threshold: 85
        issuerService:
          enabled: true
          threshold: 85
    
    prometheus:
      enabled: true
      serverAddress: "http://vmauth-raccoon.monitoring.svc.cluster.local:8427"
      metricName: "kong_request_rate"
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      threshold: "100"
      authModes: "basic"
      authentication:
        clusterTriggerAuthenticationName: "eni-keda-vmselect-creds"
    
    cron:
      enabled: true
      timezone: "Europe/Berlin"
      schedules:
      - name: "business-hours"
        start: "0 8 * * 1-5"
        end: "0 18 * * 1-5"
        desiredReplicas: 5
      - name: "night-hours"
        start: "0 22 * * *"
        end: "0 6 * * *"
        desiredReplicas: 2
```

### Example 3: Production Configuration (Conservative)

```yaml
kedaAutoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 35
  pollingInterval: 60        # Check every minute
  cooldownPeriod: 600        # 10 minute cooldown
  
  fallback:
    enabled: true
    replicas: 35              # Safe fallback count
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 600  # 10 minute stabilization
          policies:
          - type: Percent
            value: 10        # Max 10% reduction per period
            periodSeconds: 120
        scaleUp:
          stabilizationWindowSeconds: 30   # 30 second stabilization
          policies:
          - type: Pods
            value: 4         # Add 4 pod at a time
            periodSeconds: 30
  
  triggers:
    cpu:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 60          # Lower threshold for more headroom
        jumper:
          enabled: true
          threshold: 65
        issuerService:
          enabled: true
          threshold: 65
    
    memory:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 80
        jumper:
          enabled: true
          threshold: 80
        issuerService:
          enabled: true
          threshold: 80
    
    prometheus:
      enabled: true
      serverAddress: "http://vmauth-raccoon.monitoring.svc.cluster.local:8427"
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      threshold: "100"       # Higher threshold for stability
      activationThreshold: "50"
      authModes: "basic"
      authentication:
        clusterTriggerAuthenticationName: "eni-keda-vmselect-creds"
```

## Validation Rules

The following validation rules will be implemented in the Helm templates:

### 1. Mutual Exclusion with HPA

```yaml
{{- if and .Values.autoscaling.enabled .Values.kedaAutoscaling.enabled -}}
{{- fail "ERROR: Cannot enable both autoscaling (HPA) and kedaAutoscaling (KEDA). Please enable only one." -}}
{{- end }}
```

### 2. Replica Count Validation

```yaml
{{- if and .Values.kedaAutoscaling.enabled (gt .Values.kedaAutoscaling.minReplicas .Values.kedaAutoscaling.maxReplicas) -}}
{{- fail (printf "ERROR: kedaAutoscaling.minReplicas (%d) must be less than or equal to maxReplicas (%d)" .Values.kedaAutoscaling.minReplicas .Values.kedaAutoscaling.maxReplicas) -}}
{{- end }}
```

### 3. Prometheus Configuration Validation

```yaml
{{- if and .Values.kedaAutoscaling.enabled .Values.kedaAutoscaling.triggers.prometheus.enabled (not .Values.kedaAutoscaling.triggers.prometheus.serverAddress) -}}
{{- fail "ERROR: kedaAutoscaling.triggers.prometheus.serverAddress is required when prometheus trigger is enabled" -}}
{{- end }}

{{- if and .Values.kedaAutoscaling.enabled .Values.kedaAutoscaling.triggers.prometheus.enabled (not .Values.kedaAutoscaling.triggers.prometheus.authentication.clusterTriggerAuthenticationName) -}}
{{- fail "ERROR: kedaAutoscaling.triggers.prometheus.authentication.clusterTriggerAuthenticationName is required when prometheus trigger is enabled" -}}
{{- end }}
```

### 4. At Least One Trigger Enabled

```yaml
{{- if .Values.kedaAutoscaling.enabled -}}
{{- $hasEnabledTrigger := or .Values.kedaAutoscaling.triggers.cpu.enabled .Values.kedaAutoscaling.triggers.memory.enabled .Values.kedaAutoscaling.triggers.prometheus.enabled .Values.kedaAutoscaling.triggers.cron.enabled -}}
{{- if not $hasEnabledTrigger -}}
{{- fail "ERROR: At least one kedaAutoscaling trigger must be enabled (cpu, memory, prometheus, or cron)" -}}
{{- end }}
{{- end }}
```

## Template Integration Points

### 1. ScaledObject Template

**File**: `templates/scaled-object-keda.yaml`

Renders when: `kedaAutoscaling.enabled: true`

### 2. TriggerAuthentication Template

**File**: `templates/trigger-authentication-keda.yaml`

**NOTE**: This template is NOT needed when using ClusterTriggerAuthentication. The ClusterTriggerAuthentication resource (`eni-keda-vmselect-creds`) must be created separately by cluster administrators and is shared across all namespaces.

### 3. HPA Template Update

**File**: `templates/horizontal-pod-autoscaler.yaml`

Update condition from:
```yaml
{{- if .Values.autoscaling.enabled -}}
```

To:
```yaml
{{- if and .Values.autoscaling.enabled (not .Values.kedaAutoscaling.enabled) -}}
```

### 4. Deployment Template Update

**File**: `templates/deployment-kong.yml`

Update replicas section from:
```yaml
{{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicas | default 1 }}
{{- end }}
```

To:
```yaml
{{- if not (or .Values.autoscaling.enabled .Values.kedaAutoscaling.enabled) }}
  replicas: {{ .Values.replicas | default 1 }}
{{- end }}
```

## Backward Compatibility

### Default Behavior (No Changes for Existing Users)

```yaml
# Existing configuration (unchanged)
autoscaling:
  enabled: false

# New configuration (disabled by default)
kedaAutoscaling:
  enabled: false
```

**Result**: No autoscaling (same as before)

### Migration Scenarios

#### Scenario 1: User Not Using Autoscaling

**Before**:
```yaml
autoscaling:
  enabled: false
```

**After** (no changes needed):
```yaml
autoscaling:
  enabled: false

kedaAutoscaling:
  enabled: false
```

#### Scenario 2: User Using HPA

**Before**:
```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  cpuUtilizationPercentage: 80
```

**After** (continues to work):
```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  cpuUtilizationPercentage: 80

kedaAutoscaling:
  enabled: false
```

#### Scenario 3: User Migrating to KEDA

**Before**:
```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  cpuUtilizationPercentage: 80
```

**After** (disable HPA, enable KEDA):
```yaml
autoscaling:
  enabled: false

kedaAutoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  triggers:
    cpu:
      enabled: true
      containers:
        kong:
          enabled: true
          threshold: 80
        jumper:
          enabled: true
          threshold: 80
        issuerService:
          enabled: true
          threshold: 80
    memory:
      enabled: false
    prometheus:
      enabled: false
    cron:
      enabled: false
```

## Documentation Requirements

### values.yaml Comments

- Every field must have inline comment explaining purpose
- Include examples for complex fields (cron expressions, PromQL queries)
- Document default values and recommended ranges
- Reference external documentation where appropriate

### README.md Section

Add new section: "KEDA-Based Autoscaling"

Content:
- Prerequisites (KEDA installation)
- Quick start example
- Configuration reference (link to values.yaml)
- Migration guide from HPA
- Troubleshooting common issues

### CHANGELOG.md Entry

```markdown
## [X.Y.0] - 2025-MM-DD

### Added
- KEDA-based autoscaling support with CPU, memory, Prometheus, and cron triggers
- Advanced anti-flapping configuration via HPA behavior policies
- Victoria Metrics integration for custom metric scaling
- Schedule-based scaling for predictable traffic patterns
- Comprehensive autoscaling documentation and examples

### Changed
- HPA template now excludes when KEDA is enabled (mutual exclusion)
- Deployment replicas condition updated to support KEDA

### Migration
- Existing HPA configurations continue to work without changes
- KEDA is disabled by default (opt-in feature)
- See README "KEDA-Based Autoscaling" section for migration guide
```

## Testing Checklist

- [ ] `helm lint` passes with KEDA enabled
- [ ] `helm template` renders ScaledObject correctly
- [ ] Validation fails when both HPA and KEDA enabled
- [ ] Validation fails when minReplicas > maxReplicas
- [ ] Validation fails when Prometheus enabled but serverAddress empty
- [ ] Default values render valid ScaledObject
- [ ] All trigger types render correctly when enabled
- [ ] Cron schedules render correctly with multiple entries
- [ ] TriggerAuthentication renders only when needed
- [ ] Backward compatibility: existing deployments work unchanged
- [ ] Migration: HPA to KEDA transition works smoothly
- [ ] Test deployment: KEDA scales based on CPU
- [ ] Test deployment: KEDA scales based on memory
- [ ] Test deployment: KEDA scales based on Prometheus metrics
- [ ] Test deployment: KEDA scales based on cron schedules
- [ ] Anti-flapping: cooldown periods prevent rapid scaling
