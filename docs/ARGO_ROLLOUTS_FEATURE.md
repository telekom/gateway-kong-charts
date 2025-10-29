# Argo Rollouts Feature Documentation

## Overview

This Helm chart supports **Argo Rollouts** for progressive delivery with canary and blue-green deployments. When enabled, the chart deploys:

1. **Rollout Resource** - Manages the deployment with progressive delivery using `workloadRef` to the existing Deployment
2. **Canary Service** - Additional service for routing canary traffic (`{{ .Release.Name }}-proxy-canary`)
3. **AnalysisTemplates** - Automated metric-based validation for rollout decisions (optional)

## Prerequisites

- Argo Rollouts must be installed in the cluster
- NGINX Ingress Controller (for traffic routing with canary)
- Prometheus/Victoria Metrics accessible for analysis (optional, required if using AnalysisTemplates)
- Kubernetes secret containing Prometheus credentials (if using authentication for metrics)

## Configuration

### Enable Argo Rollouts

Set in your `values.yaml`:

```yaml
argoRollouts:
  enabled: true
  
  analysisTemplates:
    errorRate:
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
    successRate:
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
```

### Resources Created

When `argoRollouts.enabled=true`, the following resources are deployed:

#### 1. Rollout Resource (`templates/rollout-kong.yaml`)
- Uses `workloadRef` to manage the existing Deployment resource
- Implements canary or blue-green strategy with configurable traffic shifting
- References AnalysisTemplates for automated validation (optional)
- Uses NGINX Ingress for traffic routing via canary annotations

#### 2. Canary Service (`templates/service-proxy-canary.yml`)
- Service: `{{ .Release.Name }}-proxy-canary`
- Routes canary traffic during progressive rollout
- Same selector as stable service (`{{ .Release.Name }}-proxy`)

#### 3. AnalysisTemplates (`templates/analysistemplate-kong.yaml`) - Optional
- **error-rate-analysis**: Monitors HTTP error rate via NGINX Ingress metrics
- **success-rate-analysis**: Monitors overall success rate via NGINX Ingress metrics
- Triggers automatic rollback on failure
- Enabled via `argoRollouts.analysisTemplates.enabled=true`

## Default Canary Strategy

The default configuration implements a simple canary rollout:

```yaml
argoRollouts:
  enabled: false
  
  strategy:
    type: canary
    canary:
      additionalProperties:
        maxUnavailable: "50%"
        maxSurge: "25%"
        scaleDownDelaySeconds: 60
      
      steps:
        - setWeight: 10      # Route 10% traffic to canary
        - pause:
            duration: 2m     # Wait 2 minutes
        # Automatic promotion to 100%
      
      analysis:
        templates:
          - templateName: success-rate-analysis
        args: []
        startingStep:  # Optional: define at which step to start analysis (1-based index)
```

The Rollout uses NGINX Ingress traffic routing with canary annotations (`canary-by-header: x-canary`) to gradually shift traffic from stable to canary versions.

## Analysis Templates

Analysis templates are **optional** and use NGINX Ingress Controller metrics. Enable them with:

```yaml
argoRollouts:
  analysisTemplates:
    enabled: true
```

### Error Rate Analysis

Monitors HTTP error rate (4xx/5xx) from NGINX Ingress metrics and triggers rollback if > 5%:

```yaml
errorRate:
  enabled: true
  interval: 30s
  count: 0
  failureLimit: 2
  successCondition: "all(result, # < 0.05)"
  query: |
    sum(irate(
      nginx_ingress_controller_request_duration_seconds_count{
        exported_namespace="{{`{{ args.namespace }}`}}",
        exported_service="{{`{{ args.service-name }}`}}",
        ingress="{{`{{ args.service-name }}`}}",
        canary!="",
        status!~"5.."
      }[1m]
    )) /
    sum(irate(
      nginx_ingress_controller_request_duration_seconds_count{
        exported_namespace="{{`{{ args.namespace }}`}}",
        exported_service="{{`{{ args.service-name }}`}}",
        ingress="{{`{{ args.service-name }}`}}",
        canary!=""
      }[1m]
    ))
  prometheusAddress: ""  # Required: set your Prometheus/Victoria Metrics URL
```

### Success Rate Analysis

Monitors overall success rate from NGINX Ingress metrics and triggers rollback if < 95%:

```yaml
successRate:
  enabled: true
  interval: 30s
  count: 0
  failureLimit: 3
  successCondition: "all(result, # >= 0.95)"
  query: |
    sum(irate(
      nginx_ingress_controller_request_duration_seconds_count{
        exported_namespace="{{`{{ args.namespace }}`}}",
        exported_service="{{`{{ args.service-name }}`}}",
        ingress="{{`{{ args.service-name }}`}}",
        canary!="",
        status!~"(4|5).*"
      }[1m]
    )) /
    sum(irate(
      nginx_ingress_controller_request_duration_seconds_count{
        exported_namespace="{{`{{ args.namespace }}`}}",
        exported_service="{{`{{ args.service-name }}`}}",
        ingress="{{`{{ args.service-name }}`}}",
        canary!=""
      }[1m]
    ))
  prometheusAddress: ""  # Required: set your Prometheus/Victoria Metrics URL
```

**Note:** Both templates use NGINX Ingress Controller metrics (`nginx_ingress_controller_request_duration_seconds_count`) and require `prometheusAddress` to be configured.

## Authentication Setup

### Creating the Prometheus Secret

If your Prometheus/Victoria Metrics endpoint requires authentication, create a secret in the same namespace as your Rollout with a base64-encoded `basic-auth` key:

```bash
# Create base64 encoded user:password for Basic Auth
echo -n 'your-username:your-password' | base64

# Create the secret
kubectl create secret generic victoria-metrics-secret \
  --from-literal=basic-auth='<base64-encoded-user:password>' \
  --namespace=<your-namespace>
```

Or using a YAML manifest:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: victoria-metrics-secret
  namespace: <your-namespace>
type: Opaque
data:
  basic-auth: "<base64-encoded-user:password>"  # e.g., dXNlcjpwYXNzd29yZA==
```

The chart will use this secret for Basic Auth headers when querying Prometheus/Victoria Metrics.

### Disabling Authentication

If your Prometheus endpoint doesn't require authentication, disable it in your `values.yaml`:

```yaml
argoRollouts:
  analysisTemplates:
    errorRate:
      authentication:
        enabled: false
    successRate:
      authentication:
        enabled: false
```

## Customization

### Customize Canary Steps

Override the default steps in your `values.yaml`:

```yaml
argoRollouts:
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 20
        - pause:
            duration: 10m
        - setWeight: 50
        - pause:
            duration: 10m
        - setWeight: 100
```

### Customize Blue-Green Strategy

Configure blue-green deployment behavior:

```yaml
argoRollouts:
  strategy:
    type: blueGreen
    blueGreen:
      autoPromotionEnabled: true
      autoPromotionSeconds: 300  # Auto-promote after 5 minutes if analysis succeeds
      scaleDownDelaySeconds: 30
      previewReplicaCount: 1     # Run only 1 replica for preview
      prePromotionAnalysis:
        templates:
          - templateName: success-rate-analysis
          - templateName: error-rate-analysis
```

### Customize Analysis Thresholds

```yaml
argoRollouts:
  analysisTemplates:
    enabled: true
    
    errorRate:
      enabled: true
      interval: 1m
      count: 0
      failureLimit: 2
      successCondition: "all(result, # < 0.05)"  # 5% error threshold
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
      authentication:
        enabled: true
        secretName: "victoria-metrics-secret"
        basicKey: "basic-auth"
    
    successRate:
      enabled: true
      interval: 2m
      count: 0
      failureLimit: 3
      successCondition: "all(result, # >= 0.95)"  # 95% success threshold
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
      authentication:
        enabled: true
        secretName: "victoria-metrics-secret"
        basicKey: "basic-auth"
```

### Disable Analysis Templates

```yaml
argoRollouts:
  analysisTemplates:
    enabled: false
```

## Compatibility with Autoscaling

- **HPA (Horizontal Pod Autoscaler)**: `hpaAutoscaling.enabled` must be `false` when using Argo Rollouts
- **KEDA Autoscaling**: Can be used with Argo Rollouts - KEDA manages replica count, Argo Rollouts manages progressive delivery

The chart validates these constraints via the `argoRollouts.validate` helper and will fail with a clear error message if HPA is enabled together with Argo Rollouts.

## Testing

Test the templates with the preprod values file:

```bash
# Test Rollout resource
helm template test-release . -f values-preprod.yaml \
  --set argoRollouts.enabled=true \
  --set argoRollouts.analysisTemplates.errorRate.prometheusAddress=http://test:8427 \
  --set argoRollouts.analysisTemplates.successRate.prometheusAddress=http://test:8427 \
  --show-only templates/rollout-kong.yaml

# Test canary service
helm template test-release . -f values-preprod.yaml \
  --set argoRollouts.enabled=true \
  --show-only templates/service-proxy-canary.yml

# Test analysis templates
helm template test-release . -f values-preprod.yaml \
  --set argoRollouts.enabled=true \
  --set argoRollouts.analysisTemplates.errorRate.prometheusAddress=http://test:8427 \
  --set argoRollouts.analysisTemplates.successRate.prometheusAddress=http://test:8427 \
  --show-only templates/analysistemplate-kong.yaml
```

## Files Added/Modified

### New Files
- `templates/rollout-kong.yaml` - Rollout resource with workloadRef
- `templates/rollout-kong.yaml.license` - License header
- `templates/service-proxy-canary.yml` - Canary service
- `templates/service-proxy-canary.yml.license` - License header
- `templates/analysistemplate-kong.yaml` - Analysis templates
- `templates/analysistemplate-kong.yaml.license` - License header
- `templates/_argo-rollouts.tpl` - Helper templates
- `templates/_argo-rollouts.tpl.license` - License header

### Modified Files
- `values.yaml` - Added `argoRollouts` configuration section
- `templates/deployment-kong.yml` - Added validation and replica management for Argo Rollouts

## Example Configuration

Complete example for production use with canary deployment:

```yaml
argoRollouts:
  enabled: true
  
  strategy:
    type: canary
    canary:
      additionalProperties:
        maxUnavailable: "50%"
        maxSurge: "25%"
        scaleDownDelaySeconds: 60
      
      steps:
        - setWeight: 10
        - pause:
            duration: 2m
        - setWeight: 25
        - pause:
            duration: 3m
        - setWeight: 50
        - pause:
            duration: 5m
        - setWeight: 75
        - pause:
            duration: 5m
      
      analysis:
        templates:
          - templateName: success-rate-analysis
        args: []
        startingStep: 1  # Start analysis after first step
  
  analysisTemplates:
    enabled: true
    
    errorRate:
      enabled: true
      interval: 30s
      count: 0
      failureLimit: 2
      successCondition: "all(result, # < 0.05)"
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
      authentication:
        enabled: true
        secretName: "victoria-metrics-secret"
        basicKey: "basic-auth"
    
    successRate:
      enabled: true
      interval: 30s
      count: 0
      failureLimit: 3
      successCondition: "all(result, # >= 0.95)"
      prometheusAddress: "http://prometheus.monitoring.svc.cluster.local:8427"
      authentication:
        enabled: true
        secretName: "victoria-metrics-secret"
        basicKey: "basic-auth"
```

### Example: Blue-Green Deployment

Blue-green deployment runs two identical production environments. Only one (blue or green) serves production traffic while the other is idle or used for staging.

```yaml
argoRollouts:
  enabled: true
  
  strategy:
    type: blueGreen
    blueGreen:
      # Automatic promotion disabled - requires manual approval
      autoPromotionEnabled: false
      
      # Time to wait before scaling down the old version after promotion
      scaleDownDelaySeconds: 30
      
      # Optional: Run analysis before promoting preview to active
      prePromotionAnalysis:
        templates:
          - templateName: success-rate-analysis
      
      # Optional: Run analysis after promotion
      postPromotionAnalysis:
        templates:
          - templateName: success-rate-analysis
```

**How it works:**
1. New version deploys to preview service (`{{ .Release.Name }}-proxy-canary`)
2. Active service (`{{ .Release.Name }}-proxy`) continues serving production traffic
3. Optional pre-promotion analysis validates the preview version
4. Manual or automatic promotion switches traffic to the new version
5. Optional post-promotion analysis validates the promotion
6. Old version scales down after `scaleDownDelaySeconds`

**Note:** The `activeService` and `previewService` are automatically set by the template to `{{ .Release.Name }}-proxy` and `{{ .Release.Name }}-proxy-canary` respectively. All other blue-green configuration options can be customized via `argoRollouts.strategy.blueGreen`.

**Common Blue-Green Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `autoPromotionEnabled` | Automatically promote to active after successful analysis | `false` |
| `scaleDownDelaySeconds` | Seconds to wait before scaling down old version | (unset) |
| `prePromotionAnalysis` | AnalysisTemplate to run before promotion | (unset) |
| `postPromotionAnalysis` | AnalysisTemplate to run after promotion | (unset) |
| `previewReplicaCount` | Number of replicas for preview (defaults to spec.replicas) | (unset) |
| `autoPromotionSeconds` | Time to wait before auto-promotion (requires autoPromotionEnabled) | (unset) |

## Important Notes

- **workloadRef Strategy**: The Rollout uses `workloadRef` to manage the existing Deployment, allowing Argo Rollouts to control progressive delivery without replacing the Deployment resource
- **Replica Management**: When `argoRollouts.enabled=true` and KEDA is disabled, the Rollout manages replica count. If KEDA is enabled, KEDA manages replicas and the Rollout manages progressive delivery
- **Traffic Routing**: 
  - **Canary**: Uses NGINX Ingress Controller with canary annotations for traffic splitting. The header `x-canary` can be used to force traffic to canary version
  - **Blue-Green**: Traffic switches between active (`{{ .Release.Name }}-proxy`) and preview (`{{ .Release.Name }}-proxy-canary`) services
- **Analysis Templates**: Optional feature that requires Prometheus/Victoria Metrics. Metrics are sourced from NGINX Ingress Controller. Can be used with both canary and blue-green strategies
- **Authentication**: Analysis templates use Basic Auth with base64-encoded credentials stored in Kubernetes secrets
- **Namespace**: All resources (Rollout, Services, AnalysisTemplates, Secrets) must be in the same namespace
- **ScaleDown**: The Rollout is configured with `scaleDown: onsuccess` to clean up old ReplicaSets after successful rollout
- **Blue-Green Services**: The `activeService` and `previewService` are automatically configured and should not be overridden. Configure other blue-green options via `argoRollouts.strategy.blueGreen`
