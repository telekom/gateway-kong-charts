<!--
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Gateway Helm Chart

This Helm chart deploys the Kong-based API gateway for the [Open Telekom Integration Platform](https://github.com/telekom/Open-Telekom-Integration-Platform).

## Code of Conduct

This project has adopted the [Contributor Covenant](https://www.contributor-covenant.org/) in version 2.1 as our code of conduct. Please see the details in our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). All contributors must abide by the code of conduct.

By participating in this project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Licensing

This project follows the [REUSE standard for software licensing](https://reuse.software/).
Each file contains copyright and license information, and license texts can be found in the [./LICENSES](./LICENSES) folder. For more information visit <https://reuse.software/>.

## Installation

### Via OCI Registry

The chart is published to GitHub Container Registry and can be installed directly:

```bash
helm install my-gateway oci://ghcr.io/telekom/o28m-charts/stargate --version 9.0.0 -f my-values.yaml
```

### Via Git Repository

Alternatively, clone the repository and install from source:

```bash
git clone https://github.com/telekom/gateway-kong-charts.git
cd gateway-kong-charts
helm install my-gateway . -f my-values.yaml
```

## Requirements

### Prerequisites

- **Kubernetes Cluster**
- **Helm**: Version 3.x
- **Ingress Controller**: NGINX Ingress Controller (or compatible alternative) for external access

### Container Images

**Important:** Container images are currently not published to a public registry. You must build the images from source and push them to your own registry before installation.

See the [Gateway Repository Overview](https://github.com/telekom/Open-Telekom-Integration-Platform/blob/main/docs/repository_overview.md#gateway) for links to all required component repositories.

### Database

This Gateway requires a PostgreSQL database that will be preconfigured by the Gateway's init container. A PostgreSQL database is deployed automatically with the Gateway by default.

For production use-cases, use an external PostgreSQL database by setting `global.database.location: external` and configuring the `externalDatabase` settings in `values.yaml`.

### Certificate Management

**Manual Secrets (Required):**
You must provide JWT signing key secrets for the Issuer Service and Jumper components. Configure them using `jumper.existingJwkSecretName` and `issuerService.existingJwkSecretName` in `values.yaml`.

Both components must use identical secrets with the following three-key format:
- `prev-tls.crt`, `prev-tls.key`, `prev-tls.kid` - Previous key (for verifying older tokens)
- `tls.crt`, `tls.key`, `tls.kid` - Current key (for signing new tokens)
- `next-tls.crt`, `next-tls.key`, `next-tls.kid` - Next key (pre-distributed before becoming active)

See the [Automatic Certificate and Key Rotation](#automatic-certificate-and-key-rotation) section for details on the rotation mechanism and secret format.

### Configuration

**Important:** The default `values.yaml` is not ready for deployment out of the box. You must configure the following before installation:
- Image registry and repository settings
- Database passwords (production environments)
- Ingress hostnames and TLS certificates
- Environment-specific labels and metadata
- Resource limits and requests

Refer to the [Open Telekom Integration Platform Documentation](https://github.com/telekom/Open-Telekom-Integration-Platform/blob/main/docs/README.md#open-telekom-integration-platform-documentation) for detailed installation guides, and the [Configuration](#configuration) and [Parameters](#parameters) sections below for detailed configuration options.

## Configuration

### Image Configuration

Images are configured using a cascading defaults system with global and component-specific settings.

**Structure:**
```yaml
global:
  image:
    registry: mtr.devops.telekom.de
    namespace: eu_it_co_development/o28m

image:
  # registry: ""       # Optional: Override global.image.registry
  # namespace: ""      # Optional: Override global.image.namespace
  repository: gateway-kong
  tag: "1.1.0"
```

Images are constructed as: `{registry}/{namespace}/{repository}:{tag}`

Each component (Kong, Jumper, Issuer Service, PostgreSQL, Jobs) can override the global registry and namespace settings individually.

### Database Configuration

PostgreSQL is deployed with the Gateway and requires minimal configuration. **Important:** Change the default passwords!

### External Access

The Gateway can be accessed via Ingress resources. See the [Parameters](#parameters) section for configuration details.

### Security Context

The chart includes hardened security contexts by default that are compliant with most Kubernetes platform requirements.

**Default security contexts:**
- All containers run as non-root users
- Read-only root filesystems where applicable
- All capabilities dropped
- Privilege escalation disabled
- Component-specific user/group IDs

**Customization:**
Customize security contexts per component or globally. See `values.yaml` for all options:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  # ... additional settings

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  # ... additional settings
```

### Storage and Ingress Classes

**Storage Class:**
By default, the chart uses the cluster's default storage class. Override per component if needed:

```yaml
postgresql:
  persistence:
    storageClassName: "my-storage-class"  # Or "" for cluster default
```

**Ingress Class:**
Ingress class configuration supports cascading defaults:

```yaml
# Set global default for all ingresses
global:
  ingress:
    ingressClassName: nginx

# Or override per component
proxy:
  ingress:
    className: traefik  # Takes precedence over global setting
```

### Health Probes

The Gateway is fully operational only when all components (Kong, Jumper, Issuer Service) are healthy. This is critical for rolling updates.

Each container has its own `readinessProbe`, `livenessProbe`, and `startupProbe` configuration.

**Probe URLs:**

- `http://localhost:8100/status` as readiness probe for Kong
- `http://localhost:8100/status` as liveness probe for Kong
- `http://localhost:8100/status` as startup probe for Kong
- `http://localhost:8080/actuator/health/readiness` as readiness probe for each Jumper container ("jumper")
- `http://localhost:8080/actuator/health/liveness` as liveness probe for each Jumper container ("jumper")
- `http://localhost:8080/actuator/health/liveness` as startup probe for each Jumper container ("jumper")
- `http://localhost:8081/health` as readiness probe for each Issuer-service container
- `http://localhost:8081/health` as liveness probe for each Issuer-service container
- `http://localhost:8081/health` as startup probe for each Issuer-service container

**Configuration:**

Each component has dedicated probe settings in `values.yaml`. Undefined values use Kubernetes defaults.

| Component        | Helm Values                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `kong`           | `readinessProbe`, `livenessProbe`, `startupProbe`                                         |
| `jumper`         | `jumper.readinessProbe`, `jumper.livenessProbe`, `jumper.startupProbe`                    |
| `issuer-service` | `issuerService.readinessProbe`, `issuerService.livenessProbe`, `issuerService.startupProbe` |

**Example** (Kong container defaults):

```yaml
livenessProbe:
  httpGet:
    path: /status
    port: status
    scheme: HTTP
  timeoutSeconds: 5
  periodSeconds: 20
  failureThreshold: 4
readinessProbe:
  httpGet:
    path: /status
    port: status
    scheme: HTTP
  timeoutSeconds: 2
startupProbe:
  httpGet:
    path: /status
    port: status
    scheme: HTTP
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 1
  failureThreshold: 295
```

## Security

### Admin API Protection

**Warning:** Exposing the Admin API for Kong Community Edition is dangerous, as the API is not protected by RBAC and can be accessed by anyone with the API URL. Therefore, the Admin API Ingress is disabled by default.

The Admin API is protected via a dedicated service and route with JWT-Keycloak authentication. Configure the issuer in your values.

### htpasswd Authentication

Create htpasswd for the admin user using the Apache htpasswd tool.

**Prerequisite:** An existing `gatewayAdminApiKey` for the deployment.

1. Generate htpasswd: `htpasswd -cb htpasswd admin gatewayAdminApiKey`
2. Copy the file content into the desired secret (ensure no spaces or line breaks)
3. Verify (recommended): `htpasswd -vb htpasswd admin gatewayAdminApiKey`
4. Deploy and verify setup jobs can access the Kong Admin API and the admin route is accessible manually

### SSL Verification

When SSL verification is enabled, the Gateway verifies all traffic against a bundle of trusted CA certificates.

You can enable SSL verification by setting `sslVerify: true` in `values.yaml`. You must provide your own truststore via the `trustedCaCertificates` field with CA certificates in PEM format, otherwise Kong will fail to start.

**Example:**

```yaml
sslVerify: true
trustedCaCertificates: |
  -----BEGIN CERTIFICATE-----
  <CA certificate 01 in PEM format here>
  -----END CERTIFICATE-----
  -----BEGIN CERTIFICATE-----
  <CA certificate 02 in PEM format here>
  -----END CERTIFICATE-----
  -----BEGIN CERTIFICATE-----
  <CA certificate 03 in PEM format here>
  -----END CERTIFICATE-----
```

Helm let's you reference multiple values files during installation. You could leverage this to externalize `trustedCaCertificates` to a separate values file (e.g., `my-trusted-ca-certificates.yaml`).

### Supported TLS Versions

Supported TLS versions: TLSv1.2 and TLSv1.3. TLSv1.1 is *not* supported.

### Server Certificate

When HTTPS is used without SNI configuration, the API gateway provides a default server certificate for `https://localhost`. Replace this default with a custom certificate by specifying the secret name in `defaultTlsSecret`.

**Example:**

```yaml
defaultTlsSecret: my-https-secret
```

Here are some examples of how to create a custom TLS secret from PEM files. Refer to the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) for more details.

```sh
kubectl create secret tls my-https-secret --key=key.pem --cert=cert.pem
oc create secret generic my-https-secret-2 --from-file=tls.key=key.pem  --from-file=tls.crt=cert.pem
```

## Bootstrap and Upgrade

The chart provides specialized jobs for database migrations during initial setup and upgrades.

### Bootstrap

Bootstrapping is required when Kong starts for the first time to set up its database. Set `migrations: bootstrap` in `values.yaml` for new deployments. The bootstrap job is idempotent — running it multiple times is safe.

### Upgrade

Upgrading to a newer version may require database migrations. Set `migrations: upgrade` in `values.yaml` to run pre- and post-upgrade migration jobs.

**Warning:** Remove or comment out `migrations: upgrade` after a successful deployment to prevent re-running migrations.

**Important:** For detailed upgrade instructions, breaking changes, and migration guides, see [UPGRADE.md](UPGRADE.md).

## Advanced Features

The following sections describe advanced configuration options for production deployments.

### Autoscaling

Some environments (especially production workloads) can benefit from autoscaling to automatically adjust workload resources. This chart provides two different autoscaling options: standard HPA and KEDA-based autoscaling.

#### Standard HPA (Horizontal Pod Autoscaler)

See the [Kubernetes HPA documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) for details.

For configuration options, see the `hpaAutoscaling.*` values in the [Parameters](#parameters) section below.

#### KEDA-Based Autoscaling (Advanced)

**Available since chart version `8.0.0`**

[KEDA (Kubernetes Event-Driven Autoscaling)](https://keda.sh/) provides advanced autoscaling capabilities beyond standard HPA, including:
- **Multiple metric sources**: CPU, memory, custom metrics from Victoria Metrics, and time-based schedules
- **Anti-flapping protection**: Sophisticated cooldown periods and stabilization windows
- **Custom metrics**: Scale based on request rate, error rate, or any Prometheus/Victoria Metrics query
- **Schedule-based scaling**: Pre-scale for known traffic patterns (business hours, weekends, etc.)

**Prerequisites:**
- KEDA must be installed in the cluster: `helm install keda kedacore/keda --namespace keda --create-namespace`
- Kubernetes metrics server must be running (for CPU/memory scaling)
- Victoria Metrics must be accessible (for custom metric scaling)
- TriggerAuthentication or ClusterTriggerAuthentication resource must exist (for Victoria Metrics auth)

**Important:** `kedaAutoscaling` and `hpaAutoscaling` are mutually exclusive. Enable only one.

**Minimal Configuration** (CPU and memory only):

```yaml
kedaAutoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  triggers:
    cpu:
      enabled: true
      threshold: 70  # Scale up when CPU > 70%
    memory:
      enabled: true
      threshold: 85  # Scale up when memory > 85%
    prometheus:
      enabled: false
    cron:
      enabled: false
```

For configuration options, see the `kedaAutoscaling.*` values in the [Parameters](#parameters) section below.

**References:**
- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Victoria Metrics PromQL](https://docs.victoriametrics.com/MetricsQL.html)

### Argo Rollouts (Progressive Delivery)

**Available since chart version `8.1.0` — BETA**

**Note:** The Helm values API is in early stages. Values and templates may change in future versions.

[Argo Rollouts](https://argoproj.github.io/rollouts/) provides advanced deployment capabilities with progressive delivery strategies like canary and blue-green deployments. When enabled, Argo Rollouts manages the rollout process while maintaining the existing Deployment resource through `workloadRef`.

**Features:**
- **Canary Deployments**: Gradually shift traffic from stable to new version with configurable steps
- **Blue-Green Deployments**: Run two identical production environments (blue and green)
- **Automated Analysis**: Optional metric-based validation using Prometheus/Victoria Metrics
- **Traffic Management**: NGINX Ingress-based traffic splitting with canary annotations
- **Automated Rollbacks**: Automatic rollback based on analysis metrics (error rate, success rate)

**Prerequisites:**
- Argo Rollouts must be installed in the cluster: `kubectl create namespace argo-rollouts && kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml`
- NGINX Ingress Controller (for traffic routing)
- Prometheus/Victoria Metrics (optional, for automated analysis)

**Important:** `argoRollouts` and `hpaAutoscaling` (HPA) are mutually exclusive. KEDA autoscaling can be used together with Argo Rollouts.

**Initial Takeover from Existing Deployment**

When enabled, Argo Rollouts manages the rollout process while maintaining the existing Deployment resource through `workloadRef`. It controls scaling up new ReplicaSets and scaling down old ones. This creates a situation where the old Deployment goes out of sync with Argo CD, which attempts to scale up the old Deployment again.

Normally, the Helm chart does not render the replica field. However, during initial takeover (especially when using autoscaling), you must explicitly set replicas to 0 by configuring `argoRollouts.workloadRef.explicitDownscale=true`. After the first migration to Argo Rollouts, remove this property (it defaults to false) to resume normal operation.

**Minimal Configuration** (canary without analysis):

```yaml
argoRollouts:
  enabled: true
 
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 10
        - pause:
            duration: 2m
        - setWeight: 50
        - pause:
            duration: 5m
```

**Advanced Configuration** (canary with automated analysis):

```yaml
argoRollouts:
  enabled: true
 
  strategy:
    type: canary
    canary:
      additionalProperties:
        maxUnavailable: "50%"
        maxSurge: "25%"
        dynamicStableScale: true
     
      steps:
        - setWeight: 10
        - pause:
            duration: 2m
        - setWeight: 50
        - pause:
            duration: 5m
     
      analysis:
        templates:
          - templateName: success-rate-analysis
 
  analysisTemplates:
    enabled: true
   
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

**Blue-Green Deployment:**

```yaml
argoRollouts:
  enabled: true
 
  strategy:
    type: blueGreen
    blueGreen:
      autoPromotionEnabled: false    # Manual promotion required
      scaleDownDelaySeconds: 30      # Wait before scaling down old version
      prePromotionAnalysis:          # Optional: analysis before promotion
        templates:
          - templateName: success-rate-analysis
```

For configuration options, see the `argoRollouts.*` values in the [Parameters](#parameters) section below.

For detailed configuration, examples, and troubleshooting, see the [Argo Rollouts Feature Documentation](docs/ARGO_ROLLOUTS_FEATURE.md).

**References:**
- [Argo Rollouts Documentation](https://argoproj.github.io/rollouts/)
- [Argo Rollouts Canary Strategy](https://argoproj.github.io/rollouts/features/canary/)
- [Argo Rollouts Analysis](https://argoproj.github.io/rollouts/features/analysis/)

### Pod Anti-Affinity and Topology Key

Distribute pods across multiple nodes for high availability. If one node fails, pods on other nodes continue serving traffic.

Configure pod distribution using the `topologyKey` setting. See the [Parameters](#parameters) section for configuration options and the [Kubernetes documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity) for details on pod anti-affinity.

### Automatic Certificate and Key Rotation

**Available since chart version `6.0.0`**

The Gateway supports automatic rotation of JWT signing keys and certificates used by the Issuer Service and Jumper components. This feature provides zero-downtime key rotation with graceful transitions.

**How It Works:**

The rotation system uses a three-key approach:
- **prev-tls.*** - Previous key (for verifying older tokens)
- **tls.*** - Current key (for signing new tokens)
- **next-tls.*** - Next key (pre-distributed before becoming active)

When certificates are renewed:
1. Current key moves to previous (`tls.*` → `prev-tls.*`)
2. Next key becomes current (`next-tls.*` → `tls.*`)
3. New certificate becomes next (source → `next-tls.*`)

This ensures:
- Resource servers can verify tokens signed with the previous key
- The next key is pre-distributed before activation
- Smooth rotation despite eventual consistency in volume mount propagation

**Prerequisites:**
- [cert-manager](https://cert-manager.io/) installed and configured
- [gateway-rotator](https://github.com/telekom/gateway-rotator) operator deployed

**Configuration:**

Enable automatic rotation by setting `keyRotation.enabled=true` in `values.yaml`:

```yaml
keyRotation:
  enabled: true
```

This deploys the necessary Certificate resource that cert-manager will manage. The gateway-rotator operator watches for certificate renewals and maintains the three-key rotation pattern automatically.

For a more detailed description of the rotation mechanism, see the [gateway-rotator documentation](https://github.com/telekom/gateway-rotator).

**Manual Secret Management:**

Alternatively, provide your own secrets:

```yaml
jumper:
  existingJwkSecretName: my-custom-jwk-secret

issuerService:
  existingJwkSecretName: my-custom-jwk-secret
```

**Important:** Both components must use identical secrets. The secret must conform to the three-key format with `prev-tls.*`, `tls.*`, and `next-tls.*` fields.

**References:**
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [gateway-rotator Key Rotation Process](https://github.com/telekom/gateway-rotator#key-rotation-process)

### Kong Latency Tuning

Large updates via the Admin API can cause latency in the Gateway runtime. This is related to [Kong issue #7543](https://github.com/Kong/kong/issues/7543).

You can tune Kong's asynchronous route refresh behavior with these variables:

| Helm-Chart variable        | Kong property                      | default value | documentation link              |
| -------------------------- | ---------------------------------- | ------------- | ------------------------------- |
| nginxWorkerProcesses       | KONG_NGINX_WORKER_PROCESSES        | 4             |                                 |
| workerConsistency          | KONG_WORKER_CONSISTENCY            | eventual      | [worker_consistency]            |
| workerStateUpdateFrequency | KONG_DB_UPDATE_FREQUENCY           | 10            | [db_update_frequency]           |
| dbUpdatePropagation        | KONG_DB_UPDATE_PROPAGATION         | 0             | [db_update_propagation]         |
| dbUpdateFrequency          | KONG_WORKER_STATE_UPDATE_FREQUENCY | 10            | [worker_state_update_frequency] |

[worker_consistency]: https://docs.konghq.com/gateway/2.8.x/reference/configuration/#worker_consistency
[db_update_frequency]: https://docs.konghq.com/gateway/2.8.x/reference/configuration/#db_update_frequency
[db_update_propagation]: https://docs.konghq.com/gateway/2.8.x/reference/configuration/#db_update_propagation
[worker_state_update_frequency]: https://docs.konghq.com/gateway/2.8.x/reference/configuration/#worker_state_update_frequency

### Relabeling application metrics

In case you need to manipulate existing application metrcis or add new ones,
you can use the `metricRelableings` for both ServiceMonitor and PodMonitor resources.
An example that adds a new label would look like this:

```yaml
prometheus:
  enabled: true
  [...]

  podMonitor:
    enabled: true
    metricRelabelings:
      - action: replace
        targetLabel: example-label-key
        replacement: example-label-value
    [...]
```

## Parameters

The following table provides a comprehensive list of all configurable parameters in `values.yaml`:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| adminApi.accessLog | string | `"/dev/stdout"` | Access log target |
| adminApi.enabled | bool | `true` | Create Service for Kong Admin API |
| adminApi.errorLog | string | `"/dev/stderr"` | Error log target |
| adminApi.gatewayAdminApiKey | string | `"changeme"` | Admin API key for authentication |
| adminApi.htpasswd | string | `"admin:changeme"` | Htpasswd for Admin API basic authentication |
| adminApi.ingress.annotations | object | `{}` | Ingress annotations (merged with global.ingress.annotations) |
| adminApi.ingress.enabled | bool | `true` | Enable ingress for Admin API |
| adminApi.ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts configuration |
| adminApi.ingress.tls | list | `[]` |  |
| adminApi.tls.enabled | bool | `false` | Enable HTTPS for Admin API |
| argoRollouts.analysisTemplates.enabled | bool | `true` | Enable creation of AnalysisTemplates |
| argoRollouts.analysisTemplates.errorRate.authentication | object | `{"basicKey":"basic-auth","enabled":true,"secretName":"victoria-metrics-secret"}` | Prometheus Basic Auth authentication configuration |
| argoRollouts.analysisTemplates.errorRate.authentication.basicKey | string | `"basic-auth"` | Secret key for base64 encoded user:password Basic Auth header |
| argoRollouts.analysisTemplates.errorRate.authentication.enabled | bool | `true` | Enable authentication for Prometheus queries |
| argoRollouts.analysisTemplates.errorRate.authentication.secretName | string | `"victoria-metrics-secret"` | Secret name containing Prometheus credentials (must exist in same namespace as Rollout) Example secret:   apiVersion: v1   kind: Secret   metadata:     name: victoria-metrics-secret   type: Opaque   stringData:     username: "my-username"     password: "my-password" |
| argoRollouts.analysisTemplates.errorRate.count | int | `0` | Number of measurements to take |
| argoRollouts.analysisTemplates.errorRate.enabled | bool | `false` | Enable error rate analysis |
| argoRollouts.analysisTemplates.errorRate.failureLimit | int | `2` | Number of failed measurements that trigger rollback |
| argoRollouts.analysisTemplates.errorRate.interval | string | `"30s"` | Analysis interval (how often to check) |
| argoRollouts.analysisTemplates.errorRate.prometheusAddress | string | `""` | Prometheus server address (must be accessible) Example: "http://prometheus.monitoring.svc.cluster.local:8427" |
| argoRollouts.analysisTemplates.errorRate.query | string | `"sum(irate(\nkong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\",code!~\"5..\"}[1m]\n)) /\nsum(irate(\nkong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\"}[1m]\n))\n"` | Error rate threshold (5% = 0.05) PromQL query to calculate error rate over last 5 minutes |
| argoRollouts.analysisTemplates.errorRate.successCondition | string | `"all(result, # < 0.05)"` | Success criteria (PromQL query must return < threshold) |
| argoRollouts.analysisTemplates.successRate.authentication | object | `{"basicKey":"basic-auth","enabled":true,"secretName":"victoria-metrics-secret"}` | Prometheus Basic Auth authentication configuration |
| argoRollouts.analysisTemplates.successRate.authentication.basicKey | string | `"basic-auth"` | Secret key for base64 encoded user:password Basic Auth header |
| argoRollouts.analysisTemplates.successRate.authentication.enabled | bool | `true` | Enable authentication for Prometheus queries |
| argoRollouts.analysisTemplates.successRate.authentication.secretName | string | `"victoria-metrics-secret"` | Secret name containing Prometheus credentials |
| argoRollouts.analysisTemplates.successRate.count | int | `0` | Number of measurements to take |
| argoRollouts.analysisTemplates.successRate.enabled | bool | `true` | Enable success rate analysis |
| argoRollouts.analysisTemplates.successRate.failureLimit | int | `3` | Number of failed measurements that trigger rollback |
| argoRollouts.analysisTemplates.successRate.interval | string | `"30s"` | Analysis interval |
| argoRollouts.analysisTemplates.successRate.prometheusAddress | string | `""` | Prometheus server address |
| argoRollouts.analysisTemplates.successRate.query | string | `"sum(irate(\n  kong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\",code!~\"(4|5).*\"}[1m]\n)) /\nsum(irate(\n  kong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\"}[1m]\n))\n"` | Success rate threshold (95% = 0.95) PromQL query to calculate success rate over last 1 minute |
| argoRollouts.analysisTemplates.successRate.successCondition | string | `"all(result, # >= 0.95)"` | Success criteria (PromQL query must return > threshold) |
| argoRollouts.enabled | bool | `false` | Enable Argo Rollouts progressive delivery (replaces standard Deployment) |
| argoRollouts.strategy.blueGreen | object | `{"autoPromotionEnabled":false}` | Blue-Green strategy configuration (activeService and previewService handled by template) |
| argoRollouts.strategy.blueGreen.autoPromotionEnabled | bool | `false` | Enable automatic promotion to new version |
| argoRollouts.strategy.canary | object | `{"additionalProperties":{"dynamicStableScale":true,"maxSurge":"25%","maxUnavailable":"50%"},"analysis":{"args":[],"startingStep":null,"templates":[{"templateName":"success-rate-analysis"}]},"steps":[{"setWeight":10},{"pause":{"duration":"1m"}},{"setWeight":20},{"pause":{"duration":"1m"}},{"setWeight":40},{"pause":{"duration":"1m"}},{"setWeight":60},{"pause":{"duration":"1m"}},{"setWeight":80},{"pause":{"duration":"1m"}}]}` | Canary strategy configuration |
| argoRollouts.strategy.canary.additionalProperties | object | `{"dynamicStableScale":true,"maxSurge":"25%","maxUnavailable":"50%"}` | Additional canary deployment properties |
| argoRollouts.strategy.canary.additionalProperties.dynamicStableScale | bool | `true` | Enable dynamic stable scaling (mutually exclusive with scaleDownDelaySeconds) |
| argoRollouts.strategy.canary.additionalProperties.maxSurge | string | `"25%"` | Maximum surge pods during rollout (number or percentage) |
| argoRollouts.strategy.canary.additionalProperties.maxUnavailable | string | `"50%"` | Maximum unavailable pods during rollout (number or percentage) |
| argoRollouts.strategy.canary.analysis | object | `{"args":[],"startingStep":null,"templates":[{"templateName":"success-rate-analysis"}]}` | Background analysis configuration |
| argoRollouts.strategy.canary.analysis.args | list | `[]` | Arguments passed to analysis templates |
| argoRollouts.strategy.canary.analysis.startingStep | string | `nil` | Canary step number to start analysis (1-based index) |
| argoRollouts.strategy.canary.analysis.templates | list | `[{"templateName":"success-rate-analysis"}]` | AnalysisTemplate names for background analysis |
| argoRollouts.strategy.canary.steps | list | `[{"setWeight":10},{"pause":{"duration":"1m"}},{"setWeight":20},{"pause":{"duration":"1m"}},{"setWeight":40},{"pause":{"duration":"1m"}},{"setWeight":60},{"pause":{"duration":"1m"}},{"setWeight":80},{"pause":{"duration":"1m"}}]` | Canary deployment steps (set weight percentages and pause durations) |
| argoRollouts.strategy.type | string | `"canary"` | Deployment strategy type: "canary" or "blueGreen" |
| argoRollouts.workloadRef.explicitDownscale | bool | `false` | Enable explicit downscale of old Deployment during initial Argo Rollouts takeover with ArgoCD (see README.md) |
| argoRollouts.workloadRef.scaleDown | string | `"progressively"` | Scale-down strategy for workloadRef (progressively or immediately) |
| circuitbreaker.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for circuit breaker |
| circuitbreaker.count | int | `4` | Failure count threshold for circuit breaker activation |
| circuitbreaker.enabled | bool | `false` | Enable circuit breaker component deployment |
| circuitbreaker.image | object | `{"repository":"gateway-circuitbreaker","tag":"2.1.0"}` | Circuit breaker image configuration (inherits from global.image) |
| circuitbreaker.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for circuit breaker container |
| circuitbreaker.interval | string | `"60s"` | Check interval for circuit breaker |
| circuitbreaker.resources | object | `{"limits":{"cpu":"500m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | Circuit breaker container resource limits and requests |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for Kong container (hardened defaults) |
| dbUpdateFrequency | int | `10` | Frequency in seconds to poll database for updates |
| dbUpdatePropagation | int | `0` | Delay in seconds before propagating database updates |
| disableUpstreamCache | bool | `false` | Disable upstream response caching |
| externalDatabase.ssl | bool | `true` | Enable SSL for external database connections |
| externalDatabase.sslVerify | bool | `false` | Verify SSL certificates for external database |
| global.database.database | string | `"kong"` | Database name |
| global.database.location | string | `"local"` | Database location: 'local' (deploy with chart) or 'external' (provided externally) |
| global.database.password | string | `"changeme"` | Database password |
| global.database.port | int | `5432` | Database port |
| global.database.schema | string | `"public"` | Database schema |
| global.database.username | string | `"kong"` | Database username |
| global.environment | string | `"default"` | Environment name (e.g. playground, preprod, ...) |
| global.failOnUnsetValues | bool | `true` | Fail template rendering on unset required values |
| global.image.namespace | string | `"eu_it_co_development/o28m"` | Default image namespace |
| global.image.registry | string | `"mtr.devops.telekom.de"` | Default image registry |
| global.imagePullPolicy | string | `"IfNotPresent"` | Default image pull policy |
| global.imagePullSecrets | list | `[]` | Array of pull secret names for image pulling |
| global.ingress.annotations | object | `{}` | Common annotations for all ingress resources (can be extended per component) |
| global.labels | object | `{}` | Common labels applied to all Kubernetes resources (transferred to Prometheus metrics if ServiceMonitor is enabled) |
| global.passwordRules.enabled | bool | `false` | Enable password rule enforcement |
| global.passwordRules.length | int | `12` | Minimum password length |
| global.passwordRules.mustMatch | list | `["[a-z]","[A-Z]","[0-9]","[^a-zA-Z0-9]"]` | Password must match these regex patterns |
| global.podAntiAffinity.required | bool | `false` | Use required (hard) or preferred (soft) pod anti-affinity |
| global.preStopSleepBase | int | `30` | Base sleep duration in seconds for pre-stop lifecycle hook |
| global.tracing.collectorUrl | string | `"http://guardians-drax-collector.skoll:9411/api/v2/spans"` | Zipkin collector URL (e.g., Jaeger collector), must include http(s) scheme |
| global.tracing.defaultServiceName | string | `"stargate"` | Service name displayed in tracing UI |
| global.tracing.sampleRatio | int | `1` | Sample ratio for requests without trace IDs (0=off, 1=all requests) |
| global.zone | string | `"default"` | Zone identifier for the gateway instance (must match control plane configuration) |
| hpaAutoscaling | object | `{"cpuUtilizationPercentage":80,"enabled":false,"maxReplicas":10,"minReplicas":3}` | Horizontal Pod Autoscaler configuration |
| hpaAutoscaling.cpuUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| hpaAutoscaling.maxReplicas | int | `10` | Maximum number of replicas |
| hpaAutoscaling.minReplicas | int | `3` | Minimum number of replicas |
| image | object | `{"repository":"gateway-kong","tag":"1.3.0"}` | Kong Gateway image configuration (inherits from global.image) |
| image.tag | string | `"1.3.0"` | Kong Gateway image tag |
| imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Kong container |
| irixBrokerRoute.enabled | bool | `false` | Enable IRIX broker route |
| irixBrokerRoute.name | string | `"user-login"` | Route name |
| irixBrokerRoute.upstream | object | `{"path":"/auth/realms/eni-login","port":80,"protocol":"http","service":"irix-broker"}` | Route hostname (optional, uses default host rules if not set) host: integration.spacegate.telekom.de |
| irixBrokerRoute.upstream.path | string | `"/auth/realms/eni-login"` | Upstream service path |
| irixBrokerRoute.upstream.port | int | `80` | Upstream service port |
| irixBrokerRoute.upstream.protocol | string | `"http"` | Upstream protocol |
| irixBrokerRoute.upstream.service | string | `"irix-broker"` | Upstream service name |
| issuerService.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for Issuer Service |
| issuerService.enabled | bool | `true` | Enable Issuer Service container deployment |
| issuerService.environment | list | `[]` | Additional environment variables for Issuer Service container - {name: foo, value: bar} |
| issuerService.existingJwkSecretName | string | `nil` | Existing JWK secret name for OAuth token signing (alternative to keyRotation.enabled=true) Must be compatible with gateway-rotator format: https://github.com/telekom/gateway-rotator#key-rotation-process |
| issuerService.image | object | `{"repository":"gateway-issuer-service-go","tag":"2.2.1"}` | Issuer Service image configuration (inherits from global.image) |
| issuerService.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Issuer Service container |
| issuerService.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"timeoutSeconds":5}` | Issuer Service liveness probe configuration |
| issuerService.readinessProbe | object | `{"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"}}` | Issuer Service readiness probe configuration |
| issuerService.resources | object | `{"limits":{"cpu":"500m","memory":"50Mi"},"requests":{"cpu":"50m","memory":"10Mi"}}` | Issuer Service container resource limits and requests |
| issuerService.startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"periodSeconds":1}` | Issuer Service startup probe configuration |
| job | object | `{"image":{"repository":"bash-curl","tag":"8.13.0"}}` | Job image configuration for setup jobs (inherits from global.image) |
| jobs.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for setup jobs |
| jumper.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for Jumper |
| jumper.enabled | bool | `true` | Enable Jumper container deployment |
| jumper.environment | list | `[]` | Additional environment variables for Jumper container - {name: foo, value: bar} |
| jumper.existingJwkSecretName | string | `nil` | Existing JWK secret name for OAuth token issuance (alternative to keyRotation.enabled=true) Must be compatible with gateway-rotator format: https://github.com/telekom/gateway-rotator#key-rotation-process |
| jumper.image | object | `{"repository":"gateway-jumper","tag":"4.4.1"}` | Jumper image configuration (inherits from global.image) |
| jumper.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Jumper container |
| jumper.internetFacingZones | list | `[]` | List of zones that are considered internet-facing (empty list uses Jumper's default configuration) Example: [space, canis, aries] |
| jumper.issuerUrl | string | `"https://<your-gateway-host>/auth/realms/default"` | Issuer service URL for gateway token issuance (your gateway's auth realm endpoint) |
| jumper.jvmOpts | string | `"-XX:MaxRAMPercentage=75.0 -Dreactor.netty.pool.leasingStrategy=lifo"` | JVM options for Jumper |
| jumper.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/actuator/health/liveness","port":"jumper","scheme":"HTTP"},"timeoutSeconds":5}` | Jumper liveness probe configuration |
| jumper.port | int | `8080` | Jumper container port |
| jumper.publishEventUrl | string | `"http://producer.integration:8080/v1/events"` | Event publisher URL |
| jumper.readinessProbe | object | `{"httpGet":{"path":"/actuator/health/readiness","port":"jumper","scheme":"HTTP"},"initialDelaySeconds":5}` | Jumper readiness probe configuration |
| jumper.resources | object | `{"limits":{"cpu":"5000m","memory":"1Gi"},"requests":{"cpu":"1500m","memory":"1Gi"}}` | Jumper container resource limits and requests |
| jumper.stargateUrl | string | `"https://<your-gateway-host>"` | Gateway URL for Gateway-to-Gateway communication |
| jumper.startupProbe | object | `{"failureThreshold":285,"httpGet":{"path":"/actuator/health/readiness","port":"jumper","scheme":"HTTP"},"initialDelaySeconds":15,"periodSeconds":1}` | Jumper startup probe configuration |
| jumper.zoneHealth.databaseConnectionTimeout | int | `500` | Redis connection timeout in milliseconds |
| jumper.zoneHealth.databaseHost | string | `"localhost"` | Redis database hostname |
| jumper.zoneHealth.databaseIndex | int | `2` | Redis database index |
| jumper.zoneHealth.databasePort | int | `6379` | Redis database port |
| jumper.zoneHealth.databaseSecretKey | string | `"redis-password"` | Secret key for Redis password |
| jumper.zoneHealth.databaseSecretName | string | `"redis"` | Secret name containing Redis credentials |
| jumper.zoneHealth.databaseTimeout | int | `500` | Redis operation timeout in milliseconds |
| jumper.zoneHealth.defaultHealth | bool | `true` | Default health status when Redis is unavailable |
| jumper.zoneHealth.enabled | bool | `false` | Enable zone health monitoring |
| jumper.zoneHealth.keyChannel | string | `"stargate-zone-status"` | Redis Pub/Sub channel for zone status |
| jumper.zoneHealth.requestRate | int | `10000` | Maximum request rate per second |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig | object | `{"behavior":{"scaleDown":{"policies":[{"periodSeconds":60,"type":"Percent","value":10}],"selectPolicy":"Min","stabilizationWindowSeconds":300},"scaleUp":{"policies":[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}],"selectPolicy":"Max","stabilizationWindowSeconds":0}}}` | HPA behavior configuration (scale-up/scale-down policies) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior | object | `{"scaleDown":{"policies":[{"periodSeconds":60,"type":"Percent","value":10}],"selectPolicy":"Min","stabilizationWindowSeconds":300},"scaleUp":{"policies":[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}],"selectPolicy":"Max","stabilizationWindowSeconds":0}}` | Scaling behavior policies |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown | object | `{"policies":[{"periodSeconds":60,"type":"Percent","value":10}],"selectPolicy":"Min","stabilizationWindowSeconds":300}` | Scale-down behavior (conservative to prevent flapping) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.policies | list | `[{"periodSeconds":60,"type":"Percent","value":10}]` | Scale-down policies (multiple policies can be defined) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.selectPolicy | string | `"Min"` | Policy selection (Min = most conservative, Max = most aggressive) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.stabilizationWindowSeconds | int | `300` | Stabilization window for scale-down in seconds (KEDA waits before scaling down) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp | object | `{"policies":[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}],"selectPolicy":"Max","stabilizationWindowSeconds":0}` | Scale-up behavior (aggressive for availability) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.policies | list | `[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}]` | Scale-up policies |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.selectPolicy | string | `"Max"` | Policy selection (Max = use most aggressive policy) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.stabilizationWindowSeconds | int | `0` | Stabilization window for scale-up in seconds (0 = immediate scale-up) |
| kedaAutoscaling.advanced.restoreToOriginalReplicaCount | bool | `false` | Restore to original replica count when ScaledObject is deleted |
| kedaAutoscaling.cooldownPeriod | int | `300` | Cooldown period in seconds (minimum time between scale-down actions) Prevents rapid scale-down oscillations Recommended: 300 seconds (5 minutes) for stable workloads |
| kedaAutoscaling.enabled | bool | `false` | Enable KEDA-based autoscaling (disables standard HPA if enabled) |
| kedaAutoscaling.fallback.enabled | bool | `false` | Enable fallback to a fixed replica count when all triggers fail |
| kedaAutoscaling.fallback.replicas | int | `10` | Number of replicas to maintain when all triggers fail (e.g. maxReplicas) |
| kedaAutoscaling.maxReplicas | int | `10` | Maximum number of replicas (must be >= minReplicas) |
| kedaAutoscaling.minReplicas | int | `2` | Minimum number of replicas (must be >= 1) |
| kedaAutoscaling.pollingInterval | int | `30` | Polling interval in seconds (how often KEDA checks metrics) Lower values = more responsive but more API calls Recommended: 30-60 seconds for balanced behavior |
| kedaAutoscaling.triggers.cpu.containers | object | `{"issuerService":{"enabled":true,"threshold":70},"jumper":{"enabled":true,"threshold":70},"kong":{"enabled":true,"threshold":70}}` | Per-container CPU thresholds (any container exceeding threshold triggers scaling) |
| kedaAutoscaling.triggers.cpu.containers.issuerService | object | `{"enabled":true,"threshold":70}` | Issuer Service container CPU scaling configuration |
| kedaAutoscaling.triggers.cpu.containers.issuerService.enabled | bool | `true` | Enable CPU monitoring for Issuer Service container |
| kedaAutoscaling.triggers.cpu.containers.issuerService.threshold | int | `70` | CPU utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.cpu.containers.jumper | object | `{"enabled":true,"threshold":70}` | Jumper container CPU scaling configuration |
| kedaAutoscaling.triggers.cpu.containers.jumper.enabled | bool | `true` | Enable CPU monitoring for Jumper container |
| kedaAutoscaling.triggers.cpu.containers.jumper.threshold | int | `70` | CPU utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.cpu.containers.kong | object | `{"enabled":true,"threshold":70}` | Kong container CPU scaling configuration |
| kedaAutoscaling.triggers.cpu.containers.kong.enabled | bool | `true` | Enable CPU monitoring for Kong container |
| kedaAutoscaling.triggers.cpu.containers.kong.threshold | int | `70` | CPU utilization threshold percentage (0-100, recommended: 60-80% for headroom) |
| kedaAutoscaling.triggers.cpu.enabled | bool | `true` | Enable CPU-based scaling for any container |
| kedaAutoscaling.triggers.cron.enabled | bool | `false` | Enable cron-based (schedule) scaling |
| kedaAutoscaling.triggers.cron.schedules | list | `[]` | Cron schedule definitions (time windows with desired replica counts) Each schedule defines start/end times and replica count Multiple schedules can overlap (highest desiredReplicas wins) |
| kedaAutoscaling.triggers.cron.timezone | string | `"Europe/Berlin"` | Timezone for cron schedules Use IANA timezone database names for automatic DST handling Europe/Berlin automatically handles CET (UTC+1) and CEST (UTC+2) transitions Format: IANA timezone (e.g., "Europe/Berlin", "America/New_York", "Asia/Tokyo") See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones |
| kedaAutoscaling.triggers.memory.containers | object | `{"issuerService":{"enabled":true,"threshold":85},"jumper":{"enabled":true,"threshold":85},"kong":{"enabled":true,"threshold":95}}` | Per-container memory thresholds (any container exceeding threshold triggers scaling) |
| kedaAutoscaling.triggers.memory.containers.issuerService | object | `{"enabled":true,"threshold":85}` | Issuer Service container memory scaling configuration |
| kedaAutoscaling.triggers.memory.containers.issuerService.enabled | bool | `true` | Enable memory monitoring for Issuer Service container |
| kedaAutoscaling.triggers.memory.containers.issuerService.threshold | int | `85` | Memory utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.memory.containers.jumper | object | `{"enabled":true,"threshold":85}` | Jumper container memory scaling configuration |
| kedaAutoscaling.triggers.memory.containers.jumper.enabled | bool | `true` | Enable memory monitoring for Jumper container |
| kedaAutoscaling.triggers.memory.containers.jumper.threshold | int | `85` | Memory utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.memory.containers.kong | object | `{"enabled":true,"threshold":95}` | Kong container memory scaling configuration |
| kedaAutoscaling.triggers.memory.containers.kong.enabled | bool | `true` | Enable memory monitoring for Kong container |
| kedaAutoscaling.triggers.memory.containers.kong.threshold | int | `95` | Memory utilization threshold percentage (0-100, recommended: 80-90%) |
| kedaAutoscaling.triggers.memory.enabled | bool | `true` | Enable memory-based scaling for any container |
| kedaAutoscaling.triggers.prometheus.activationThreshold | string | `""` | Activation threshold (optional) Minimum metric value to activate this scaler Prevents scaling from 0 on minimal load |
| kedaAutoscaling.triggers.prometheus.authModes | string | `"basic"` | Authentication mode for Victoria Metrics Options: "basic", "bearer", "tls" |
| kedaAutoscaling.triggers.prometheus.authentication | object | `{"kind":"ClusterTriggerAuthentication","name":"eni-keda-vmselect-creds"}` | KEDA authentication configuration for Victoria Metrics access Reference to existing TriggerAuthentication or ClusterTriggerAuthentication resource |
| kedaAutoscaling.triggers.prometheus.authentication.kind | string | `"ClusterTriggerAuthentication"` | Authentication kind: "ClusterTriggerAuthentication" or "TriggerAuthentication" Use "TriggerAuthentication" for namespace-scoped environments Use "ClusterTriggerAuthentication" for cluster-wide shared credentials |
| kedaAutoscaling.triggers.prometheus.authentication.name | string | `"eni-keda-vmselect-creds"` | Name of the TriggerAuthentication or ClusterTriggerAuthentication resource This resource must be created separately and contain Victoria Metrics credentials Example ClusterTriggerAuthentication:   apiVersion: keda.sh/v1alpha1   kind: ClusterTriggerAuthentication   metadata:     name: eni-keda-vmselect-creds   spec:     secretTargetRef:     - parameter: username       name: victoria-metrics-secret       key: username     - parameter: password       name: victoria-metrics-secret       key: password  Example TriggerAuthentication (namespace-scoped):   apiVersion: keda.sh/v1alpha1   kind: TriggerAuthentication   metadata:     name: vmselect-creds     namespace: my-namespace   spec:     secretTargetRef:     - parameter: username       name: victoria-metrics-secret       key: username     - parameter: password       name: victoria-metrics-secret       key: password |
| kedaAutoscaling.triggers.prometheus.enabled | bool | `true` | Enable Prometheus/Victoria Metrics based scaling |
| kedaAutoscaling.triggers.prometheus.metricName | string | `"kong_request_rate"` | Metric name (used for identification in KEDA) |
| kedaAutoscaling.triggers.prometheus.query | string | `"sum(rate(kong_http_requests_total{ei_telekom_de_zone=\"{{ .Values.global.zone }}\",ei_telekom_de_environment=\"{{ .Values.global.environment }}\",app_kubernetes_io_instance=\"{{ .Release.Name }}-kong\"}[1m]))"` | PromQL query to execute Must return a single numeric value Can use Helm template variables (e.g., {{ .Values.global.zone }}) Example queries:   - Request rate: sum(rate(kong_http_requests_total{zone="zone1"}[1m]))   - Error rate: sum(rate(kong_http_requests_total{status=~"5.."}[1m])) |
| kedaAutoscaling.triggers.prometheus.serverAddress | string | `""` | Victoria Metrics server address (REQUIRED if enabled) Example: "http://prometheus.monitoring.svc.cluster.local:8427" Can use template variables: "{{ .Values.global.vmauth.url }}" |
| kedaAutoscaling.triggers.prometheus.threshold | string | `"100"` | Threshold value for the metric Scales up when query result exceeds this value For request rate: total requests/second across all pods |
| keyRotation.additionalSpecValues | object | `{}` | Additional Certificate resource configuration for cert-manager |
| keyRotation.enabled | bool | `false` | Enable automatic certificate/key rotation for OAuth token signing |
| livenessProbe | object | `{"failureThreshold":4,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"periodSeconds":20,"timeoutSeconds":5}` | Kong liveness probe configuration |
| logFormat | string | `"json"` | Nginx log format: debug, default, json, or plain |
| memCacheSize | string | `"128m"` | Kong memory cache size for database entities |
| migrations | string | `"none"` | Migration mode for database initialization or upgrades |
| nginxHttpLuaSharedDict | string | `"prometheus_metrics 15m"` | Nginx HTTP Lua shared dictionary for storing metrics |
| nginxWorkerProcesses | int | `4` | Number of nginx worker processes |
| pdb.create | bool | `false` | Enable PodDisruptionBudget creation |
| pdb.maxUnavailable | string | `nil` | Maximum unavailable pods (number or percentage, defaults to 1 if both unset) |
| pdb.minAvailable | string | `nil` | Minimum available pods (number or percentage) |
| plugins.acl.pluginId | string | `"bc823d55-83b5-4184-b03f-ce63cd3b75c7"` | Plugin ID for Kong configuration |
| plugins.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for plugin containers |
| plugins.enabled | list | `["rate-limiting-merged"]` | Additional Kong plugins to enable (beyond bundled and jwt-keycloak) |
| plugins.jwtKeycloak.allowedIss | list | `["https://<your-iris-host>/auth/realms/rover"]` | Allowed identity provider issuer URLs (used for authenticating Admin API requests from the Rover realm) |
| plugins.jwtKeycloak.enabled | bool | `true` | Enable JWT Keycloak plugin |
| plugins.jwtKeycloak.pluginId | string | `"b864d58b-7183-4889-8b32-0b92d6c4d513"` | Plugin ID for Kong configuration |
| plugins.prometheus.enabled | bool | `true` | Enable Prometheus metrics plugin |
| plugins.prometheus.path | string | `"/metrics"` | Metrics endpoint path |
| plugins.prometheus.pluginId | string | `"3d232d3c-dc2b-4705-aa8d-4e07c4e0ff4c"` | Plugin ID for Kong configuration |
| plugins.prometheus.podMonitor.enabled | bool | `false` | Enable PodMonitor for Prometheus Operator |
| plugins.prometheus.podMonitor.metricRelabelings | list | `[]` | Can be used to manipulate metric labels at scrape time |
| plugins.prometheus.podMonitor.selector | string | `"guardians-raccoon"` | PodMonitor selector label |
| plugins.prometheus.port | int | `9542` | Metrics endpoint port |
| plugins.prometheus.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor for Prometheus Operator |
| plugins.prometheus.serviceMonitor.metricRelabelings | list | `[]` | Can be used to manipulate metric labels at scrape time |
| plugins.prometheus.serviceMonitor.selector | string | `"guardians-raccoon"` | ServiceMonitor selector label |
| plugins.requestSizeLimiting.enabled | bool | `true` | Enable request size limiting plugin |
| plugins.requestSizeLimiting.pluginId | string | `"1e199eee-f592-4afa-8371-6b61dcbd1904"` | Plugin ID for Kong configuration |
| plugins.requestTransformer.pluginId | string | `"e9fb4272-0aff-4208-9efa-6bfec5d9df53"` | Plugin ID for Kong configuration |
| plugins.zipkin.enabled | bool | `true` | Enable distributed tracing via ENI Zipkin plugin |
| plugins.zipkin.pluginId | string | `"e8ff1211-816f-4d93-9011-a4b194586073"` | Plugin ID for Kong configuration |
| podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsUser":100,"supplementalGroups":[1000]}` | Pod security context for Kong deployment (hardened defaults) |
| postgresql.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":999,"runAsNonRoot":true,"runAsUser":999}` | Container security context for PostgreSQL |
| postgresql.deployment | object | `{"annotations":{}}` | Additional deployment annotations |
| postgresql.image | object | `{"repository":"postgresql","tag":"16.5"}` | PostgreSQL image configuration (inherits from global.image) |
| postgresql.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for PostgreSQL container |
| postgresql.maxConnections | string | `"100"` | Maximum number of client connections |
| postgresql.maxPreparedTransactions | string | `"0"` | Maximum prepared transactions (0 disables prepared transactions) |
| postgresql.persistence.keepOnDelete | bool | `false` | Keep PVC on chart deletion |
| postgresql.persistence.mountDir | string | `"/var/lib/postgresql/data"` | Data directory mount path |
| postgresql.persistence.resources | object | `{"requests":{"storage":"1Gi"}}` | Storage resource requests |
| postgresql.podSecurityContext | object | `{"fsGroup":999,"supplementalGroups":[999]}` | Pod security context for PostgreSQL |
| postgresql.resources | object | `{"limits":{"cpu":"100m","memory":"500Mi"},"requests":{"cpu":"20m","memory":"200Mi"}}` | PostgreSQL container resource limits and requests |
| postgresql.sharedBuffers | string | `"32MB"` | Shared memory buffer size for data caching |
| proxy.accessLog | string | `"/dev/stdout"` | Access log target |
| proxy.errorLog | string | `"/dev/stderr"` | Error log target |
| proxy.ingress.annotations | object | `{}` | Ingress annotations (merged with global.ingress.annotations) |
| proxy.ingress.enabled | bool | `true` | Enable ingress for proxy |
| proxy.ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts configuration |
| proxy.ingress.tls | list | `[]` | TLS configuration (secretName optional for cloud load balancers) |
| proxy.tls.enabled | bool | `false` | Enable TLS for proxy |
| readinessProbe | object | `{"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"timeoutSeconds":2}` | Kong readiness probe configuration |
| replicas | int | `1` | Number of Kong pod replicas (ignored when HPA, KEDA, or Argo Rollouts is enabled) |
| resources | object | `{"limits":{"cpu":"2500m","memory":"4Gi"},"requests":{"cpu":"1500m","memory":"3Gi"}}` | Kong container resource limits and requests |
| setupJobs.activeDeadlineSeconds | int | `3600` | Maximum job duration in seconds |
| setupJobs.backoffLimit | int | `15` | Maximum number of retries for failed jobs |
| setupJobs.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for setup jobs |
| setupJobs.resources | object | `{"limits":{"cpu":"500m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | Resource limits and requests for setup jobs |
| ssl | object | `{"cipherSuite":"custom","ciphers":"DHE-DSS-AES128-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES128-CCM:DHE-RSA-AES256-CCM:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-CCM:ECDHE-ECDSA-AES256-CCM:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_SHA256","protocols":"TLSv1.2 TLSv1.3"}` | Default HTTPS server certificate secret name (route-specific certificates can be configured at runtime) defaultTlsSecret: "mysecret" TLS protocol and cipher configuration |
| ssl.cipherSuite | string | `"custom"` | TLS cipher suite: modern, intermediate, old, or custom (see https://wiki.mozilla.org/Security/Server_Side_TLS) |
| ssl.ciphers | string | `"DHE-DSS-AES128-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES128-CCM:DHE-RSA-AES256-CCM:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-CCM:ECDHE-ECDSA-AES256-CCM:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_SHA256"` | Custom TLS ciphers (OpenSSL format, ignored unless cipherSuite is 'custom') |
| ssl.protocols | string | `"TLSv1.2 TLSv1.3"` | Allowed TLS protocols |
| sslVerify | bool | `false` | Enable SSL certificate verification for upstream traffic |
| sslVerifyDepth | string | `"1"` | SSL certificate verification depth |
| startupProbe | object | `{"failureThreshold":295,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":1,"timeoutSeconds":1}` | Kong startup probe configuration |
| strategy | object | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}` | Deployment strategy configuration |
| templateChangeTriggers | list | `[]` | List of template files for which a checksum annotation will be created |
| topologyKey | string | `"kubernetes.io/hostname"` | Topology key for pod anti-affinity (spread pods across zones for high availability) |
| workerConsistency | string | `"eventual"` | Kong worker consistency mode (eventual or strict) |
| workerStateUpdateFrequency | int | `10` | Frequency in seconds to poll for worker state updates |

## Troubleshooting

If the Gateway deployment fails to start, check the container logs for error messages.

### SSL Verification Error

**Symptom:**

```
Error: /usr/local/share/lua/5.1/opt/kong/cmd/start.lua:37: nginx configuration is invalid (exit code 1):
nginx: [emerg] SSL_CTX_load_verify_locations("/usr/local/opt/kong/tif/trusted-ca-certificates.pem") failed (SSL: error:0B084088:x509 certificate routines:X509_load_cert_crl_file:no certificate or crl found)
nginx: configuration file /opt/kong/nginx.conf test failed
```

**Solution:**
This error occurs when `sslVerify` is set to `true` but no valid certificates are provided. Either:
- Set `trustedCaCertificates` with valid CA certificates in PEM format
- Set `sslVerify: false` if SSL verification is not required
