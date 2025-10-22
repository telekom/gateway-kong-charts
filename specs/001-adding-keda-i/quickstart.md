# Quickstart Guide: KEDA Autoscaling for Gateway

**Date**: 2025-10-14  
**Feature**: KEDA-Based Autoscaling for Gateway  
**Purpose**: Step-by-step guide for operators to enable and configure KEDA autoscaling

## Prerequisites

Before enabling KEDA autoscaling, ensure the following are in place:

### 1. KEDA Installation

KEDA must be installed in your Kubernetes cluster.

**Check if KEDA is installed**:
```bash
kubectl get deployment -n keda keda-operator
```

**Install KEDA** (if not present):
```bash
# Add KEDA Helm repository
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Install KEDA
helm install keda kedacore/keda --namespace keda --create-namespace
```

**Verify KEDA is running**:
```bash
kubectl get pods -n keda
# Should show keda-operator and keda-metrics-apiserver pods running
```

### 2. Kubernetes Metrics Server

Required for CPU and memory scaling.

**Check if metrics server is installed**:
```bash
kubectl get deployment -n kube-system metrics-server
```

**Verify metrics are available**:
```bash
kubectl top nodes
kubectl top pods -n <your-namespace>
```

### 3. Victoria Metrics Access (Optional)

Required only if using Prometheus/Victoria Metrics trigger for custom metrics.

**Requirements**:
- Victoria Metrics server address (e.g., `http://vmauth-raccoon.monitoring.svc.cluster.local:8427`)
- ClusterTriggerAuthentication resource (`eni-keda-vmselect-creds`) must exist
- Network access from KEDA pods to Victoria Metrics

**Verify ClusterTriggerAuthentication exists**:
```bash
kubectl get clustertriggerauthentication eni-keda-vmselect-creds
```

**Note**: The ClusterTriggerAuthentication is typically created by cluster administrators and is shared across all namespaces. If it doesn't exist, contact your cluster administrator to create it with Victoria Metrics credentials.

## Quick Start: Minimal Configuration

### Step 1: Disable Existing HPA (if enabled)

If you're currently using the standard HPA, disable it first:

```yaml
# values.yaml
autoscaling:
  enabled: false  # Disable HPA
```

### Step 2: Enable KEDA with CPU and Memory Scaling

Create a `values-keda.yaml` file:

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
          threshold: 70  # Scale up when kong CPU > 70%
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
          threshold: 85  # Scale up when kong memory > 85%
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

### Step 3: Deploy the Chart

```bash
helm upgrade --install stargate . \
  -f values.yaml \
  -f values-keda.yaml \
  --namespace <your-namespace>
```

### Step 4: Verify KEDA is Working

**Check ScaledObject is created**:
```bash
kubectl get scaledobject -n <your-namespace>
```

**Check HPA created by KEDA**:
```bash
kubectl get hpa -n <your-namespace>
# Should show an HPA managed by KEDA
```

**View scaling events**:
```bash
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
```

**Monitor pod count**:
```bash
kubectl get pods -n <your-namespace> -w
# Watch as pods scale up/down based on load
```

## Full Configuration: All Triggers

### Step 1: Prepare Victoria Metrics Configuration

**Verify ClusterTriggerAuthentication exists**:
```bash
kubectl get clustertriggerauthentication eni-keda-vmselect-creds
```

If it doesn't exist, contact your cluster administrator. The resource should look like:
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
    namespace: monitoring
  - parameter: password
    name: victoria-metrics-secret
    key: password
    namespace: monitoring
```

**Test Victoria Metrics connectivity**:
```bash
# From a pod in your namespace
curl -u username:password \
  "http://vmauth-raccoon.monitoring.svc.cluster.local:8427/api/v1/query?query=up"
```

### Step 2: Create Comprehensive Configuration

Create `values-keda-full.yaml`:

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
            value: 50
            periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
          - type: Percent
            value: 100
            periodSeconds: 60
          - type: Pods
            value: 2
            periodSeconds: 60
          selectPolicy: Max
  
  triggers:
    # CPU scaling (per-container)
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
    
    # Memory scaling (per-container)
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
    
    # Victoria Metrics scaling
    prometheus:
      enabled: true
      serverAddress: "http://vmauth-raccoon.monitoring.svc.cluster.local:8427"
      metricName: "kong_request_rate"
      query: 'sum(rate(kong_http_requests_total{tardis_telekom_de_zone="{{ .Values.global.zone }}"}[1m]))'
      threshold: "100"
      authModes: "basic"
      authentication:
        clusterTriggerAuthenticationName: "eni-keda-vmselect-creds"
    
    # Schedule-based scaling
    cron:
      enabled: true
      timezone: "Europe/Berlin"  # Automatically handles CET/CEST
      schedules:
      - name: "business-hours"
        start: "0 8 * * 1-5"    # 8 AM Mon-Fri
        end: "0 18 * * 1-5"     # 6 PM Mon-Fri
        desiredReplicas: 5
      - name: "night-hours"
        start: "0 22 * * *"     # 10 PM daily
        end: "0 6 * * *"        # 6 AM daily
        desiredReplicas: 2
```

### Step 3: Deploy with Full Configuration

```bash
helm upgrade --install stargate . \
  -f values.yaml \
  -f values-keda-full.yaml \
  --namespace <your-namespace>
```

### Step 4: Verify All Triggers

**Check ScaledObject details**:
```bash
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
```

Look for:
- All triggers listed (cpu, memory, prometheus, cron)
- Current metric values
- Scaling events

**Check ClusterTriggerAuthentication** (for Prometheus):
```bash
kubectl get clustertriggerauthentication eni-keda-vmselect-creds
kubectl describe clustertriggerauthentication eni-keda-vmselect-creds
```

**Monitor KEDA metrics**:
```bash
# View KEDA operator logs
kubectl logs -n keda deployment/keda-operator -f

# View metrics server logs
kubectl logs -n keda deployment/keda-metrics-apiserver -f
```

## Migration from HPA to KEDA

### Current HPA Configuration

If you're currently using the standard HPA:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  cpuUtilizationPercentage: 80
```

### Migration Steps

**Step 1: Document current behavior**
- Note current min/max replicas
- Observe current scaling patterns
- Document any issues or desired improvements

**Step 2: Create equivalent KEDA configuration**

```yaml
# Disable HPA
autoscaling:
  enabled: false

# Enable KEDA with equivalent settings
kedaAutoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  
  triggers:
    cpu:
      enabled: true
      threshold: 80  # Same as HPA cpuUtilizationPercentage
    
    memory:
      enabled: false  # HPA didn't have memory, add if desired
    
    prometheus:
      enabled: false  # Add custom metrics if desired
    
    cron:
      enabled: false  # Add schedules if desired
```

**Step 3: Test in non-production first**

Deploy to a test environment and verify:
- Scaling behavior matches expectations
- No unexpected scale-up/down events
- Metrics are being collected correctly

**Step 4: Deploy to production during low-traffic period**

```bash
# Deploy during maintenance window
helm upgrade stargate . \
  -f values.yaml \
  -f values-keda.yaml \
  --namespace production
```

**Step 5: Monitor closely for 24-48 hours**

Watch for:
- Unexpected scaling events
- Metric collection issues
- Performance degradation

**Step 6: Tune configuration based on observations**

Adjust thresholds, cooldown periods, and stabilization windows as needed.

## Testing and Validation

### Test CPU-Based Scaling

**Generate CPU load**:
```bash
# From inside a gateway pod
kubectl exec -it <pod-name> -n <your-namespace> -- sh
# Run CPU-intensive command
yes > /dev/null &
```

**Observe scaling**:
```bash
# Watch pod count increase
kubectl get pods -n <your-namespace> -w

# Check CPU metrics
kubectl top pods -n <your-namespace>

# View scaling events
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
```

**Stop load and observe scale-down**:
```bash
# Kill the CPU load
kubectl exec -it <pod-name> -n <your-namespace> -- killall yes

# Wait for cooldown period (default 5 minutes)
# Watch pod count decrease
kubectl get pods -n <your-namespace> -w
```

### Test Memory-Based Scaling

**Generate memory pressure**:
```bash
# From inside a gateway pod
kubectl exec -it <pod-name> -n <your-namespace> -- sh
# Allocate memory (adjust size as needed)
stress --vm 1 --vm-bytes 1G --vm-hang 300
```

**Observe scaling** (same as CPU test above)

### Test Prometheus/Victoria Metrics Scaling

**Generate traffic**:
```bash
# Use a load testing tool (e.g., hey, wrk, k6)
hey -z 5m -c 50 https://your-gateway-url/
```

**Check Victoria Metrics query**:
```bash
# Query Victoria Metrics directly
curl -u username:password \
  "http://vmauth-raccoon.monitoring.svc.cluster.local:8427/api/v1/query?query=sum(rate(kong_http_requests_total{tardis_telekom_de_zone=\"zone1\"}[1m]))"
```

**Observe scaling based on request rate**

### Test Cron-Based Scaling

**Verify schedule configuration**:
```bash
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
# Check "Triggers" section for cron entries
```

**Wait for schedule transition**:
- Note current time and next schedule transition
- Watch pod count at transition time
- Verify replicas change to configured desiredReplicas

**Manual test** (optional):
```bash
# Temporarily adjust cron schedule to trigger in 2 minutes
# Update values and redeploy
# Watch for scaling event
```

## Troubleshooting

### Issue: ScaledObject not created

**Symptoms**:
```bash
kubectl get scaledobject -n <your-namespace>
# No resources found
```

**Diagnosis**:
```bash
# Check Helm release
helm list -n <your-namespace>

# Check for template errors
helm template stargate . -f values.yaml -f values-keda.yaml | grep -A 20 "kind: ScaledObject"
```

**Common causes**:
- `kedaAutoscaling.enabled` is `false`
- Template rendering error (check validation rules)
- KEDA CRDs not installed

**Solution**:
```bash
# Verify KEDA CRDs exist
kubectl get crd scaledobjects.keda.sh

# If missing, reinstall KEDA
helm upgrade --install keda kedacore/keda --namespace keda
```

### Issue: Prometheus trigger not working

**Symptoms**:
- ScaledObject shows "Unknown" for Prometheus metric
- No scaling based on custom metrics

**Diagnosis**:
```bash
# Check ScaledObject status
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
# Look for error messages in Events section

# Check ClusterTriggerAuthentication
kubectl describe clustertriggerauthentication eni-keda-vmselect-creds

# Check KEDA operator logs
kubectl logs -n keda deployment/keda-operator | grep -i error
```

**Common causes**:
- Victoria Metrics unreachable
- Authentication credentials incorrect
- Query syntax error
- Network policy blocking access

**Solution**:
```bash
# Test Victoria Metrics connectivity from KEDA namespace
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n keda -- \
  curl -u username:password \
  "http://vmauth-raccoon.monitoring.svc.cluster.local:8427/api/v1/query?query=up"

# Test query syntax in Victoria Metrics UI
# Adjust query in values.yaml if needed
```

### Issue: Rapid scaling (flapping)

**Symptoms**:
- Pods scaling up and down frequently
- Many scaling events in short time

**Diagnosis**:
```bash
# Check scaling events
kubectl get events -n <your-namespace> --sort-by='.lastTimestamp' | grep -i scale

# Check metric values over time
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
```

**Common causes**:
- Thresholds too close to actual load
- Cooldown period too short
- Stabilization window too short
- Oscillating metrics

**Solution**:
Adjust anti-flapping settings:

```yaml
kedaAutoscaling:
  cooldownPeriod: 600  # Increase to 10 minutes
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 600  # Increase stabilization
          policies:
          - type: Percent
            value: 25  # Reduce scale-down rate
            periodSeconds: 120
```

### Issue: Not scaling up fast enough

**Symptoms**:
- High load but pods not scaling quickly
- Performance degradation during traffic spikes

**Diagnosis**:
```bash
# Check current replica count vs max
kubectl get deployment <release-name> -n <your-namespace>

# Check metric values
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>
```

**Common causes**:
- Thresholds too high
- Scale-up stabilization window too long
- Polling interval too long
- Max replicas reached

**Solution**:
Adjust for faster scale-up:

```yaml
kedaAutoscaling:
  pollingInterval: 15  # Check more frequently
  maxReplicas: 20  # Increase if hitting limit
  
  triggers:
    cpu:
      threshold: 60  # Lower threshold for earlier scale-up
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 0  # Immediate scale-up
          policies:
          - type: Pods
            value: 3  # Add more pods per period
            periodSeconds: 60
```

### Issue: KEDA and HPA conflict

**Symptoms**:
```bash
helm upgrade fails with error:
"ERROR: Cannot enable both autoscaling (HPA) and kedaAutoscaling (KEDA)"
```

**Solution**:
Ensure only one is enabled:

```yaml
autoscaling:
  enabled: false  # Disable HPA

kedaAutoscaling:
  enabled: true  # Enable KEDA
```

### Issue: Cron schedule not triggering

**Symptoms**:
- Replicas don't change at scheduled time
- No cron-related events

**Diagnosis**:
```bash
# Check ScaledObject cron triggers
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace>

# Check current time vs schedule
date -u  # Verify UTC time
```

**Common causes**:
- Cron expression syntax error
- Timezone mismatch
- Schedule window already passed
- Overlapping schedules

**Solution**:
```bash
# Validate cron expression
# Use online validator: https://crontab.guru/

# Verify timezone
kubectl describe scaledobject <release-name>-scaledobject -n <your-namespace> | grep timezone

# Note: Europe/Berlin automatically handles CET (winter) and CEST (summer) transitions

# Test with near-future schedule
# Set start time to 2 minutes from now
```

## Performance Tuning

### Conservative Configuration (Stable Production)

```yaml
kedaAutoscaling:
  minReplicas: 5  # Higher minimum for safety
  maxReplicas: 15
  pollingInterval: 60  # Check every minute
  cooldownPeriod: 600  # 10 minute cooldown
  
  triggers:
    cpu:
      threshold: 60  # Lower threshold, more headroom
    memory:
      threshold: 75
    prometheus:
      threshold: "150"  # Higher threshold for stability
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 600
          policies:
          - type: Percent
            value: 25  # Slow scale-down
            periodSeconds: 120
```

### Aggressive Configuration (Cost Optimization)

```yaml
kedaAutoscaling:
  minReplicas: 1  # Lower minimum for cost savings
  maxReplicas: 30  # Higher maximum for burst capacity
  pollingInterval: 15  # Check frequently
  cooldownPeriod: 180  # 3 minute cooldown
  
  triggers:
    cpu:
      threshold: 80  # Higher threshold
    memory:
      threshold: 90
    prometheus:
      threshold: "200"
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 180
          policies:
          - type: Percent
            value: 50  # Faster scale-down
            periodSeconds: 60
        scaleUp:
          policies:
          - type: Pods
            value: 5  # Aggressive scale-up
            periodSeconds: 60
```

## Best Practices

1. **Start Conservative**: Begin with high thresholds and long cooldowns, tune based on observations
2. **Test in Non-Production**: Always test KEDA configuration in dev/staging before production
3. **Monitor Closely**: Watch scaling behavior for 24-48 hours after enabling
4. **Use Multiple Triggers**: Combine CPU, memory, and custom metrics for comprehensive coverage
5. **Document Decisions**: Comment why specific thresholds were chosen in values.yaml
6. **Set Realistic Limits**: Ensure maxReplicas doesn't exceed cluster capacity
7. **Plan for Failures**: Enable fallback configuration for when metrics are unavailable
8. **Use Cron for Predictable Patterns**: Pre-scale before known traffic increases
9. **Secure Credentials**: Always use Kubernetes Secrets, never hardcode passwords
10. **Version Control**: Keep KEDA configuration in version control with other Helm values

## Next Steps

After successfully enabling KEDA:

1. **Monitor and Tune**: Observe scaling behavior and adjust thresholds
2. **Add Custom Metrics**: Identify application-specific metrics for scaling
3. **Implement Schedules**: Add cron schedules for predictable traffic patterns
4. **Cost Analysis**: Compare infrastructure costs before/after KEDA
5. **Performance Validation**: Verify p95 latency remains acceptable during scaling
6. **Documentation**: Document your specific configuration and tuning decisions
7. **Alerting**: Set up alerts for scaling failures or metric unavailability
8. **Capacity Planning**: Ensure cluster has sufficient resources for max replicas

## Additional Resources

- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA Scalers Reference](https://keda.sh/docs/scalers/)
- [Victoria Metrics PromQL Guide](https://docs.victoriametrics.com/MetricsQL.html)
- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cron Expression Guide](https://crontab.guru/)
