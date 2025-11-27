<!--
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Gateway Helm Chart

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

### Database

This Gateway requires a PostgreSQL database that will be preconfigured by the Gateway's init container.

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

No detailed configuration is necessary. PostgreSQL will be deployed together with the Gateway. You should change the default passwords!

### Routes, Services, etc. via job

If you want to add routes, services, etc. you can set specific curl command to deploy you preferc configuration.

### External access

The Gateway can be accessed via created Ingress/Route. See the Parameters section for details.

## Security

### Community Edition

Be aware that exposing the Admin-API for Community Edition can be dangerous, as the API is not protected by any RBAC. Thus it can be accessed by anyone having access to the API url. \
Therefore the Admin-API-Ingress is disabled. For Mor details see [External access](#External-access).

By default, we protect the Admin API via a dedicated service and route together with the jwt-keycloak. You need to add the used issuer.

### SSL Verification

If you enable SSL verification the Gateway will try to verify all traffic against a bundle of trusted CA certificates which needs to be specified explicitely.
You can enable this by setting sslVerify to true in the `values.yaml`. If you do so, you must provide your own truststore by setting the `trustedCaCertificates` field with the content of your CA certificates in PEM format otherwise Kong won't start.

Example _values.yaml_:

```yaml
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

Of course Helm let's you reference multiple values files when installing a deployment so you could also outsource `trustedCaCertificates` wo its own values file, for example `my-trustes-ca-certificates.yaml`.

### Supported TLS versions

Only TLS versions TLSv1.2 and TLSv.1.3 are allowed. TLSv1.1 is NOT supported.

### Server Certificate

If "https" is used but no SNI is configured, the API gateway provides a default server certificate issued for "<https://localhost>". You can replace the default certificate by a custom server-certificate by specyfing the secret name in the variable `defaultTlsSecret`.

Example _values.yaml_:

```yaml
defaultTlsSecret: my-https-secret
```

Here are some examples how to create a corresponding secret from PEM files. For more details s. Kubernetes documentation.

```sh
kubectl create secret tls my-https-secret --key=key.pem --cert=cert.pem
oc create secret generic my-https-secret-2 --from-file=tls.key=key.pem  --from-file=tls.crt=cert.pem
```

## Bootstrap and Upgrade

Setup and some upgrades require specific migration steps to be run before and after changing the Kong version via a newer image or starting it for the first time.
There the chart provides specialised jobs for each of those steps.

### Bootstrap

Bootstrapping is required when Kong starts for the first time and needs to setup its database. This task is handled by the job `job-kong-bootstrap.yml`.
It will be run if "`migrations: bootstrap`" is set in the `values.yaml`. This can be uncommented if no further execution is wished, but this is also prohibited by keeping the job itself.
Running the job again will do no harm in any way, as the executed bootstrap recognises the database as already initialised.
If you deploy a new instance of this Gateway, make sure migrations is set to `bootstrap`.

### Upgrade

Upgrading to a newer version may require running migration steps (e.g. database changes). To run those jobs set "`migrations: upgrade`" in the `values.yaml`.
As a result `job-kong-pre-upgrade-migrations.yml` will run and `job-kong-post-upgrade-migrations.yml` will be run after successfull deployments to complete the upgrade.

**Warning:** Uncomment "`migrations: upgrade`" if you deploy again after a successfull deployment or set it to "`migrations: bootstrap`". Otherwise migrations will be executed again.

**Note:** Those jobs are only meant to be used for upgrading.

**Important:** For detailed upgrade instructions, breaking changes, and migration guides between versions, please refer to [UPGRADE.md](UPGRADE.md).

## htpasswd

You can create the htpasswd for admin user with Apache htpasswd tool.

**Prerequisit:** existing gatewayAdminApiKey for the deployment.

1. Execute the following statement: `htpasswd -cb htpasswd admin gatewayAdminApiKey`
2. Look up the htpasswd file you've just created and copy its content into the desired secret. \
   Make sure no spaces or line breaks are copied.
3. Optional but recommended: check if htpasswd is valid: `htpasswd -vb htpasswd admin gatewayAdminApiKey`
4. Deploy and check if setup jobs can access the Kong admin-api and also if amin-api is accessible via the admin-api-route.

## Advanced Features

During the operation of the Gateway we discovered some issues that need some more advanced Kong or Kubernetes settings.
The following paragraph explains which helm-chart settings are responsible, how to use them and what effects they have.

### Autoscaling

#### Standard HPA (Horizontal Pod Autoscaler)

In some environments, especially in AWS "prod", we use the autoscaler to update workload ressources.

The autoscaling is documented [in the HPA section](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).
(Since chart version `5.4.0` we use kubernetes API `autoscaling/v2`)

Following helm-chart variables controls the autoscaler properties for the Gateway:

| Helm-Chart variable                       | Kubernetes property (HorizontalPodAutoscaler)     | default value | documentation link |
| ----------------------------------------- | ------------------------------------------------- | ------------- | ------------------ |
| `hpaAutoscaling.enabled`                  |                                                   | false         |                    |
| `hpaAutoscaling.minReplicas`              | `spec.minReplicas`                                | 3             | [k8s_hpe_spec]     |
| `hpaAutoscaling.maxReplicas`              | `spec.maxReplicas`                                | 10            | [k8s_hpe_spec]     |
| `hpaAutoscaling.cpuUtilizationPercentage` | `spec.metrics.resource.target.averageUtilization` | 80            | [k8s_hpe_spec]     |

[k8s_hpe_spec]: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/#HorizontalPodAutoscalerSpec

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

**Important:** `kedaAutoscaling` and `autoscaling` (HPA) are mutually exclusive. Enable only one at a time.

**Minimal Configuration Example** (CPU + Memory only):

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

For a complete configuration example with all available options, see the `values.yaml` file.

**Key Configuration Options:**

| Helm-Chart variable                                                  | Description                                      | Default |
|----------------------------------------------------------------------|--------------------------------------------------|---------|
| `kedaAutoscaling.enabled`                                            | Enable KEDA autoscaling                          | `false` |
| `kedaAutoscaling.minReplicas`                                        | Minimum replica count                            | `2`     |
| `kedaAutoscaling.maxReplicas`                                        | Maximum replica count                            | `10`    |
| `kedaAutoscaling.pollingInterval`                                    | Metric check frequency (seconds)                 | `30`    |
| `kedaAutoscaling.cooldownPeriod`                                     | Scale-down cooldown (seconds)                    | `300`   |
| **CPU Triggers (Per-Container)**                                     |                                                  |         |
| `kedaAutoscaling.triggers.cpu.enabled`                               | Enable CPU-based scaling for any container       | `true`  |
| `kedaAutoscaling.triggers.cpu.containers.kong.enabled`               | Enable CPU monitoring for kong container         | `true`  |
| `kedaAutoscaling.triggers.cpu.containers.kong.threshold`             | CPU threshold for kong container (%)             | `70`    |
| `kedaAutoscaling.triggers.cpu.containers.jumper.enabled`             | Enable CPU monitoring for jumper container       | `true`  |
| `kedaAutoscaling.triggers.cpu.containers.jumper.threshold`           | CPU threshold for jumper container (%)           | `70`    |
| `kedaAutoscaling.triggers.cpu.containers.issuerService.enabled`      | Enable CPU monitoring for issuer-service         | `true`  |
| `kedaAutoscaling.triggers.cpu.containers.issuerService.threshold`    | CPU threshold for issuer-service (%)             | `70`    |
| **Memory Triggers (Per-Container)**                                  |                                                  |         |
| `kedaAutoscaling.triggers.memory.enabled`                            | Enable memory-based scaling for any container    | `true`  |
| `kedaAutoscaling.triggers.memory.containers.kong.enabled`            | Enable memory monitoring for kong container      | `true`  |
| `kedaAutoscaling.triggers.memory.containers.kong.threshold`          | Memory threshold for kong container (%)          | `85`    |
| `kedaAutoscaling.triggers.memory.containers.jumper.enabled`          | Enable memory monitoring for jumper container    | `true`  |
| `kedaAutoscaling.triggers.memory.containers.jumper.threshold`        | Memory threshold for jumper container (%)        | `85`    |
| `kedaAutoscaling.triggers.memory.containers.issuerService.enabled`   | Enable memory monitoring for issuer-service      | `true`  |
| `kedaAutoscaling.triggers.memory.containers.issuerService.threshold` | Memory threshold for issuer-service (%)          | `85`    |
| **Other Triggers**                                                   |                                                  |         |
| `kedaAutoscaling.triggers.prometheus.enabled`                        | Enable custom metric scaling (Victoria Metrics)  | `true`  |
| `kedaAutoscaling.triggers.cron.enabled`                              | Enable schedule-based scaling                    | `false` |

**References:**
- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Victoria Metrics PromQL](https://docs.victoriametrics.com/MetricsQL.html)

### Argo Rollouts (Progressive Delivery - BETA)

**Available since chart version `8.1.0`**

Please note that the helm value api is in early state and values as well as templates are suspect to change, which might break your configuration.

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

**Initial take over from an existing deployment**

When Argo Rollouts takes over responsibility for the gateway pods, it controls scaling up the new ReplicaSet and scaling down the old one. This creates a situation where the old Deployment goes out of sync with Argo CD, which attempts to scale up the old Deployment again.
Normally, the Helm chart does not render the replica field. However, during the initial takeover—especially when using autoscaling—you must explicitly set replicas to 0 once by configuring `argoRollouts.workloadRef.explicitDownscale=true`.
After the first migration to Argo Rollouts, remove this property (it defaults to false) to resume normal operation.

**Minimal Configuration Example** (Canary without analysis):

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

**Advanced Configuration Example** (Canary with automated analysis):

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

**Blue-Green Deployment Example**:

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

**Key Configuration Options:**

| Helm-Chart variable                                    | Description                                           | Default  |
|--------------------------------------------------------|-------------------------------------------------------|----------|
| `argoRollouts.enabled`                                 | Enable Argo Rollouts progressive delivery             | `false`  |
| `argoRollouts.strategy.type`                           | Strategy type: "canary" or "blueGreen"                | `canary` |
| `argoRollouts.strategy.canary.steps`                   | Canary rollout steps (weight, pause, analysis)        | See docs |
| `argoRollouts.strategy.canary.analysis.startingStep`   | Step at which to start background analysis            | (unset)  |
| `argoRollouts.strategy.blueGreen`                      | Blue-green strategy configuration (autoPromotionEnabled, scaleDownDelaySeconds, etc.) | See docs |
| `argoRollouts.analysisTemplates.enabled`               | Enable automated analysis templates                   | `true`   |
| `argoRollouts.analysisTemplates.errorRate.enabled`     | Enable error rate analysis                            | `true`   |
| `argoRollouts.analysisTemplates.successRate.enabled`   | Enable success rate analysis                          | `true`   |

For detailed configuration, examples, and troubleshooting, see the [Argo Rollouts Feature Documentation](docs/ARGO_ROLLOUTS_FEATURE.md).

**References:**
- [Argo Rollouts Documentation](https://argoproj.github.io/rollouts/)
- [Argo Rollouts Canary Strategy](https://argoproj.github.io/rollouts/features/canary/)
- [Argo Rollouts Analysis](https://argoproj.github.io/rollouts/features/analysis/)

### PodAntiaffinity & TopologyKey

In Kubernetes it is recommended to distribute the pods over several nodes. If a kubernetes node gets into problems, there are enough pods on other nodes to take on the load.
For this reason we provide the `topologyKey` flag in our helm-chart.

| Helm-Chart variable | Kubernetes property (Deployment,Pod)        | default value          | documentation link |
| ------------------- | ------------------------------------------- | ---------------------- | ------------------ |
| `topologyKey`       | `spec.affinity.podAntiAffinity.topologyKey` | kubernetes.io/hostname | [topologyKey]      |

[topologyKey]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity

### Security Context

The chart includes hardened security contexts by default that are compliant with most Kubernetes platform requirements.

**Default Security Contexts:**
- All containers run as non-root user
- Read-only root filesystems where applicable
- Dropped capabilities (ALL)
- No privilege escalation
- Specific user/group IDs configured per component

**Customization:**
Security contexts can be customized per component or globally. See `values.yaml` for all available options:

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

### readinessProbe & livenessProbe

This Gateway is fully operational only when all components Kong, Jumper and Issuer-Service are operational. This is especially important when deploying as "Rolling Update" in customer environments.
For this reason, each container deployed in a gateway pod has its own settings for `readinessProbe`, `livenessProbe` and `startupProbe` as well as configurable values for all health probes options.

The Probe-URLs are configured as follows:

- `http://localhost:8100/status` as readiness probe for Kong
- `http://localhost:8100/status` as liveness probe for Kong
- `http://localhost:8100/status` as startup probe for Kong
- `http://localhost:8080/actuator/health/readiness` as readiness probe for each Jumper container ("jumper")
- `http://localhost:8080/actuator/health/liveness` as liveness probe for each Jumper container ("jumper")
- `http://localhost:8080/actuator/health/liveness` as startup probe for each Jumper container ("jumper")
- `http://localhost:8081/health` as readiness probe for each Issuer-service container
- `http://localhost:8081/health` as liveness probe for each Issuer-service container
- `http://localhost:8081/health` as startup probe for each Issuer-service container

Each component within a stargate pod can be configured with its own settings for `readinessProbe`, `livenessProbe` and `startupProbe` as well as configurable values for all health probes options.

For this, each component has its own section in the `values.yaml` file with minimum defaults according to http path as well as own defaults where recommended. All values not defined there lead to usage of kubernetes defaults for those.

| Component        | Helm values for health probe configs                                                      |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `kong`           | `readinessProbe`,`livenessProbe`,`startupProbe`                                           |
| `jumper`         | `jumper.readinessProbe`,`jumper.livenessProbe`,`jumper.startupProbe`                      |
| `issuer-service` | `issuerService.readinessProbe`,`issuerService.livenessProbe`,`issuerService.startupProbe` |

For example the default for the kong container is the following which allows to change and overwrite all available properties without the need of redefining all defaults from kubernetes here in the chart:

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

### Latency in Kong (chart 5.2.2)

With the default setting, Kong has the following problem: while Rover is doing larger updates via the Admin-API (keyword "Reconciller"),unacceptable latencies arise in the Gateway runtime.

The problem is similar to the following already reported but still open [issue #7543](https://github.com/Kong/kong/issues/7543) in Github

The solution to the problem seems to be in asynchronous refresh or routes and tuning with the following Kong variables:

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

## Parameters

This is a short overlook about important parameters in the `values.yaml`.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| adminApi.accessLog | string | `"/dev/stdout"` | Set the log target for access log |
| adminApi.enabled | bool | `true` | Create service for accessing Kong Admin API |
| adminApi.errorLog | string | `"/dev/stderr"` | Set the log target for error log |
| adminApi.gatewayAdminApiKey | string | `"changeme"` |  |
| adminApi.htpasswd | string | `"admin:changeme"` |  |
| adminApi.ingress.annotations | object | `{}` | Merges specific into global ingress annotations |
| adminApi.ingress.enabled | bool | `true` | Create ingress for Admin API. Default depends on Edition (CE: false, EE: true) |
| adminApi.ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Set usual ingress array of hosts |
| adminApi.ingress.tls | list | `[]` |  |
| adminApi.tls.enabled | bool | `false` | Access Admin API via https instead of http   |
| argoRollouts.analysisTemplates.enabled | bool | `true` | Enable creation of AnalysisTemplates |
| argoRollouts.analysisTemplates.errorRate.authentication | object | `{"basicKey":"basic-auth","enabled":true,"secretName":"victoria-metrics-secret"}` | Prometheus authentication using Basic Auth Credentials are read from a Kubernetes secret in the same namespace |
| argoRollouts.analysisTemplates.errorRate.authentication.basicKey | string | `"basic-auth"` | Secret key containing base64 encoded user:password combination to be used as Basic Auth header |
| argoRollouts.analysisTemplates.errorRate.authentication.enabled | bool | `true` | Enable authentication for Prometheus queries |
| argoRollouts.analysisTemplates.errorRate.authentication.secretName | string | `"victoria-metrics-secret"` | Secret name containing Prometheus credentials This secret must exist in the same namespace as the Rollout Example secret creation:   apiVersion: v1   kind: Secret   metadata:     name: victoria-metrics-secret   type: Opaque   stringData:     username: "my-username"     password: "my-password" |
| argoRollouts.analysisTemplates.errorRate.count | int | `0` | Number of measurements to take |
| argoRollouts.analysisTemplates.errorRate.enabled | bool | `false` | Enable error rate analysis |
| argoRollouts.analysisTemplates.errorRate.failureLimit | int | `2` | Number of failed measurements that trigger rollback |
| argoRollouts.analysisTemplates.errorRate.interval | string | `"30s"` | Analysis interval (how often to check) |
| argoRollouts.analysisTemplates.errorRate.prometheusAddress | string | `""` | Prometheus server address (must be accessible) Example: "http://prometheus.monitoring.svc.cluster.local:8427" |
| argoRollouts.analysisTemplates.errorRate.query | string | `"sum(irate(\nkong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\",code!~\"5..\"}[1m]\n)) /\nsum(irate(\nkong_http_requests_total{ei_telekom_de_zone=\"{{ args.zone }}\",ei_telekom_de_environment=\"{{ args.environment }}\",app_kubernetes_io_instance=\"{{ args.instance }}\",route=~\"{{ args.route-regex }}\",role=\"canary\"}[1m]\n))\n"` | Error rate threshold (5% = 0.05) PromQL query to calculate error rate over last 5 minutes |
| argoRollouts.analysisTemplates.errorRate.successCondition | string | `"all(result, # < 0.05)"` | Success criteria (PromQL query must return < threshold) |
| argoRollouts.analysisTemplates.successRate.authentication | object | `{"basicKey":"basic-auth","enabled":true,"secretName":"victoria-metrics-secret"}` | Prometheus authentication using Basic Auth Credentials are read from a Kubernetes secret in the same namespace |
| argoRollouts.analysisTemplates.successRate.authentication.basicKey | string | `"basic-auth"` | Secret key containing base64 encoded user:password combination to be used as Basic Auth header |
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
| argoRollouts.strategy.blueGreen | object | `{"autoPromotionEnabled":false}` | blueGreen strategy configuration (except activeService and previewService - these are handled by template) |
| argoRollouts.strategy.canary.additionalProperties.dynamicStableScale | bool | `true` | Enable dynamic stable scale (mutual exclusive to scaleDownDelaySeconds ) |
| argoRollouts.strategy.canary.additionalProperties.maxSurge | string | `"25%"` | Maximum number of extra pods that can be created during rollout (number or percentage) |
| argoRollouts.strategy.canary.additionalProperties.maxUnavailable | string | `"50%"` | Maximum number of pods that can be unavailable during rollout (number or percentage) |
| argoRollouts.strategy.canary.analysis.args | list | `[]` | Arguments to pass to the analysis template |
| argoRollouts.strategy.canary.analysis.startingStep | string | `nil` | Canary step at which to start the analysis (1-based index) |
| argoRollouts.strategy.canary.analysis.templates | list | `[{"templateName":"success-rate-analysis"}]` | AnalysisTemplate references for background analysis |
| argoRollouts.strategy.canary.steps | list | `[{"setWeight":10},{"pause":{"duration":"1m"}},{"setWeight":20},{"pause":{"duration":"1m"}},{"setWeight":40},{"pause":{"duration":"1m"}},{"setWeight":60},{"pause":{"duration":"1m"}},{"setWeight":80},{"pause":{"duration":"1m"}}]` | Canary step definition with a weight of 10% and a pause of 5 minutes |
| argoRollouts.strategy.type | string | `"canary"` | Deployment strategy type: "canary" or "blueGreen" |
| argoRollouts.workloadRef.explicitDownscale | bool | `false` | enable explicit downscale of old Deployment during first take over of pod responsibility through argo rollouts together with argocd (see README.md for details) |
| argoRollouts.workloadRef.scaleDown | string | `"progressively"` | scaleDown strategy for Argo Rollouts deployment workloadRef |
| circuitbreaker.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for Circuitbreaker |
| circuitbreaker.count | int | `4` | Number of failures before triggering circuit breaker |
| circuitbreaker.enabled | bool | `false` | enable deployment of circuitbreaker component |
| circuitbreaker.image | object | `{"repository":"gateway-circuitbreaker","tag":"2.1.0"}` | Circuitbreaker image configuration (inherits global.image.registry and global.image.namespace) |
| circuitbreaker.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Circuitbreaker container |
| circuitbreaker.interval | string | `"60s"` | Interval for circuitbreaker checks |
| circuitbreaker.resources | object | `{"limits":{"cpu":0.5,"memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | circuitbreaker container default resource configuration |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for Kong container (hardened defaults) |
| dbUpdateFrequency | int | `10` | Frequency in seconds to poll database for updates |
| dbUpdatePropagation | int | `0` | Delay in seconds before propagating database updates |
| disableUpstreamCache | bool | `false` |  |
| externalDatabase.ssl | bool | `true` |  |
| externalDatabase.sslVerify | bool | `false` |  |
| global.database.database | string | `"kong"` | Name of the database |
| global.database.location | string | `"local"` | Determine if the a database will be deployed togehter with Stargate (local) or is provided (external) |
| global.database.password | string | `"changeme"` | The users password |
| global.database.port | int | `5432` | Port of the database |
| global.database.schema | string | `"public"` | Name of the schema |
| global.database.username | string | `"kong"` | Username for accessing the database |
| global.environment | string | `"default"` | Environment name (e.g. playground, preprod, ...) |
| global.failOnUnsetValues | bool | `true` |  |
| global.image.namespace | string | `"eu_it_co_development/o28m"` | Default namespace for all images |
| global.image.registry | string | `"mtr.devops.telekom.de"` | Default registry for all images |
| global.imagePullPolicy | string | `"IfNotPresent"` | global default for imagePullPolicy |
| global.imagePullSecrets | string | `nil` | array of pull secret names to use for image pulling |
| global.ingress.annotations | object | `{}` | Set annotations for all ingress, can be extended by ingress specific ones |
| global.labels | object | `{}` | Common labels applied to all Kubernetes resources If you have .Values.plugins.prometheus.servicemonitor.enabled=true, these labels will be transferred onto the ingested metrics. |
| global.passwordRules.enabled | bool | `false` |  |
| global.passwordRules.length | int | `12` |  |
| global.passwordRules.mustMatch[0] | string | `"[a-z]"` |  |
| global.passwordRules.mustMatch[1] | string | `"[A-Z]"` |  |
| global.passwordRules.mustMatch[2] | string | `"[0-9]"` |  |
| global.passwordRules.mustMatch[3] | string | `"[^a-zA-Z0-9]"` |  |
| global.podAntiAffinity.required | bool | `false` | configure pod anti affinity to be requiredDuringSchedulingIgnoredDuringExecution or preferredDuringSchedulingIgnoredDuringExecution |
| global.preStopSleepBase | int | `30` |  |
| global.tracing.collectorUrl | string | `"http://guardians-drax-collector.skoll:9411/api/v2/spans"` | URL of the Zipkin-Collector (e.g. Jaeger-Collector), http(s) mandatory |
| global.tracing.defaultServiceName | string | `"stargate"` | Name of the service shown in e.g. Jaeger |
| global.tracing.sampleRatio | int | `1` | How often to sample requests that do not contain trace ids. Set to 0 to turn sampling off, or to 1 to sample all requests. |
| global.zone | string | `"default"` | The zone of the gateway instance. This needs to match up with configuration done in other components like the control plane. |
| hpaAutoscaling | object | `{"cpuUtilizationPercentage":80,"enabled":false,"maxReplicas":10,"minReplicas":3}` | Horizontal Pod Autoscaler configuration |
| hpaAutoscaling.cpuUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| hpaAutoscaling.maxReplicas | int | `10` | Maximum number of replicas |
| hpaAutoscaling.minReplicas | int | `3` | Minimum number of replicas |
| image | object | `{"repository":"gateway-kong","tag":"1.2.1"}` | Kong Gateway image configuration (inherits global.image.registry and global.image.namespace) |
| imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Kong container |
| irixBrokerRoute.enabled | bool | `false` |  |
| irixBrokerRoute.name | string | `"user-login"` |  |
| irixBrokerRoute.upstream.path | string | `"/auth/realms/eni-login"` |  |
| irixBrokerRoute.upstream.port | int | `80` |  |
| irixBrokerRoute.upstream.protocol | string | `"http"` |  |
| irixBrokerRoute.upstream.service | string | `"irix-broker"` |  |
| issuerService.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for Issuer Service |
| issuerService.enabled | bool | `true` | enable deployment of issuer-service container inside gateway pod |
| issuerService.environment | list | `[]` | generic injection possibility for additional environment variables - {name: foo, value: bar} |
| issuerService.existingJwkSecretName | string | `nil` | configure manually externally managed secret for oauth (as alternative for keyRotation.enabled=true)  |
| issuerService.image | object | `{"repository":"gateway-issuer-service-go","tag":"2.2.1"}` | Issuer Service image configuration (inherits global.image.registry and global.image.namespace) |
| issuerService.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Issuer Service container |
| issuerService.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"timeoutSeconds":5}` | issuerService livenessProbe configuration |
| issuerService.readinessProbe | object | `{"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"}}` | issuerService readinessProbe configuration |
| issuerService.resources | object | `{"limits":{"cpu":"500m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | issuerService container default resource configuration |
| issuerService.startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"periodSeconds":1}` | issuerService startupProbe configuration |
| job | object | `{"image":{"repository":"bash-curl","tag":"8.13.0"}}` | Job image configuration (inherits global.image.registry and global.image.namespace) |
| jobs | object | `{"containerSecurityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}}` | Job container security context |
| jumper.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context for Jumper |
| jumper.enabled | bool | `true` | enable deployment of jumper conatiner inside gateway pod |
| jumper.environment | list | `[]` | generic injection possibility for additional environment variables - {name: foo, value: bar} |
| jumper.existingJwkSecretName | string | `nil` | configure manually externally managed secret for oauth access token issueing (as alternative for keyRotation.enabled=true)  |
| jumper.image | object | `{"repository":"gateway-jumper","tag":"4.2.5"}` | Jumper image configuration (inherits global.image.registry and global.image.namespace) |
| jumper.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Jumper container |
| jumper.internetFacingZones | list | `[]` | list of zones that are considered internet facing |
| jumper.issuerUrl | string | `"https://<your-gateway-host>/auth/realms/default"` | URL of the gateway-issuer-service, which is the issuer of the gateway tokens This should point to your gateway's auth realm endpoint |
| jumper.jvmOpts | string | `"-XX:MaxRAMPercentage=75.0 -Dreactor.netty.pool.leasingStrategy=lifo"` |  |
| jumper.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/actuator/health/liveness","port":"jumper","scheme":"HTTP"},"timeoutSeconds":5}` | jumper livenessProbe configuration |
| jumper.port | int | `8080` | Port for Jumper container |
| jumper.publishEventUrl | string | `"http://producer.integration:8080/v1/events"` |  |
| jumper.readinessProbe | object | `{"httpGet":{"path":"/actuator/health/readiness","port":"jumper","scheme":"HTTP"},"initialDelaySeconds":5}` | jumper readinessProbe configuration |
| jumper.resources | object | `{"limits":{"cpu":5,"memory":"1500Mi"},"requests":{"cpu":2,"memory":"1Gi"}}` | jumper container default resource configuration |
| jumper.stargateUrl | string | `"https://<your-gateway-host>"` | The gateway URL used for gateway-to-gateway communication |
| jumper.startupProbe | object | `{"failureThreshold":285,"httpGet":{"path":"/actuator/health/readiness","port":"jumper","scheme":"HTTP"},"initialDelaySeconds":15,"periodSeconds":1}` | jumper startupProbe configuration |
| jumper.zoneHealth.databaseConnectionTimeout | int | `500` |  |
| jumper.zoneHealth.databaseHost | string | `"localhost"` |  |
| jumper.zoneHealth.databaseIndex | int | `2` |  |
| jumper.zoneHealth.databasePort | int | `6379` |  |
| jumper.zoneHealth.databaseSecretKey | string | `"redis-password"` |  |
| jumper.zoneHealth.databaseSecretName | string | `"redis"` |  |
| jumper.zoneHealth.databaseTimeout | int | `500` |  |
| jumper.zoneHealth.defaultHealth | bool | `true` |  |
| jumper.zoneHealth.enabled | bool | `false` |  |
| jumper.zoneHealth.keyChannel | string | `"stargate-zone-status"` |  |
| jumper.zoneHealth.requestRate | int | `10000` |  |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig | object | `{"behavior":{"scaleDown":{"policies":[{"periodSeconds":60,"type":"Percent","value":10}],"selectPolicy":"Min","stabilizationWindowSeconds":300},"scaleUp":{"policies":[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}],"selectPolicy":"Max","stabilizationWindowSeconds":0}}}` | HPA behavior configuration (scale-up/scale-down policies) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.policies | list | `[{"periodSeconds":60,"type":"Percent","value":10}]` | Scale-down policies (multiple policies can be defined) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.selectPolicy | string | `"Min"` | Policy selection (Min = most conservative, Max = most aggressive) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleDown.stabilizationWindowSeconds | int | `300` | Stabilization window for scale-down (seconds) KEDA waits this long before scaling down to ensure load is sustained |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.policies | list | `[{"periodSeconds":60,"type":"Percent","value":100},{"periodSeconds":60,"type":"Pods","value":4}]` | Scale-up policies |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.selectPolicy | string | `"Max"` | Policy selection (Max = use most aggressive policy) |
| kedaAutoscaling.advanced.horizontalPodAutoscalerConfig.behavior.scaleUp.stabilizationWindowSeconds | int | `0` | Stabilization window for scale-up (seconds) 0 = immediate scale-up for availability |
| kedaAutoscaling.advanced.restoreToOriginalReplicaCount | bool | `false` | Restore to original replica count when ScaledObject is deleted |
| kedaAutoscaling.cooldownPeriod | int | `300` | Cooldown period in seconds (minimum time between scale-down actions) Prevents rapid scale-down oscillations Recommended: 300 seconds (5 minutes) for stable workloads |
| kedaAutoscaling.enabled | bool | `false` | Enable KEDA-based autoscaling (disables standard HPA if enabled) |
| kedaAutoscaling.fallback.enabled | bool | `false` | Enable fallback to a fixed replica count when all triggers fail |
| kedaAutoscaling.fallback.replicas | int | `10` | Number of replicas to maintain when all triggers fail (e.g. maxReplicas) |
| kedaAutoscaling.maxReplicas | int | `10` | Maximum number of replicas (must be >= minReplicas) |
| kedaAutoscaling.minReplicas | int | `2` | Minimum number of replicas (must be >= 1) |
| kedaAutoscaling.pollingInterval | int | `30` | Polling interval in seconds (how often KEDA checks metrics) Lower values = more responsive but more API calls Recommended: 30-60 seconds for balanced behavior |
| kedaAutoscaling.triggers.cpu.containers | object | `{"issuerService":{"enabled":true,"threshold":70},"jumper":{"enabled":true,"threshold":70},"kong":{"enabled":true,"threshold":70}}` | Per-container CPU thresholds Each container in the pod can have its own threshold If ANY container exceeds its threshold, scaling is triggered |
| kedaAutoscaling.triggers.cpu.containers.issuerService.enabled | bool | `true` | Enable CPU monitoring for issuer-service container |
| kedaAutoscaling.triggers.cpu.containers.issuerService.threshold | int | `70` | CPU utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.cpu.containers.jumper.enabled | bool | `true` | Enable CPU monitoring for jumper container |
| kedaAutoscaling.triggers.cpu.containers.jumper.threshold | int | `70` | CPU utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.cpu.containers.kong.enabled | bool | `true` | Enable CPU monitoring for kong container |
| kedaAutoscaling.triggers.cpu.containers.kong.threshold | int | `70` | CPU utilization threshold percentage (0-100) Recommended: 60-80% for headroom |
| kedaAutoscaling.triggers.cpu.enabled | bool | `true` | Enable CPU-based scaling for any container |
| kedaAutoscaling.triggers.cron.enabled | bool | `false` | Enable cron-based (schedule) scaling |
| kedaAutoscaling.triggers.cron.schedules | list | `[]` | List of cron schedules Each schedule defines a time window and desired replica count Multiple schedules can overlap (highest desiredReplicas wins) |
| kedaAutoscaling.triggers.cron.timezone | string | `"Europe/Berlin"` | Timezone for cron schedules Use IANA timezone database names for automatic DST handling Europe/Berlin automatically handles CET (UTC+1) and CEST (UTC+2) transitions Format: IANA timezone (e.g., "Europe/Berlin", "America/New_York", "Asia/Tokyo") See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones |
| kedaAutoscaling.triggers.memory.containers | object | `{"issuerService":{"enabled":true,"threshold":85},"jumper":{"enabled":true,"threshold":85},"kong":{"enabled":true,"threshold":95}}` | Per-container memory thresholds Each container in the pod can have its own threshold If ANY container exceeds its threshold, scaling is triggered |
| kedaAutoscaling.triggers.memory.containers.issuerService.enabled | bool | `true` | Enable memory monitoring for issuer-service container |
| kedaAutoscaling.triggers.memory.containers.issuerService.threshold | int | `85` | Memory utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.memory.containers.jumper.enabled | bool | `true` | Enable memory monitoring for jumper container |
| kedaAutoscaling.triggers.memory.containers.jumper.threshold | int | `85` | Memory utilization threshold percentage (0-100) |
| kedaAutoscaling.triggers.memory.containers.kong.enabled | bool | `true` | Enable memory monitoring for kong container |
| kedaAutoscaling.triggers.memory.containers.kong.threshold | int | `95` | Memory utilization threshold percentage (0-100) Recommended: 80-90% (higher than CPU due to less elasticity) |
| kedaAutoscaling.triggers.memory.enabled | bool | `true` | Enable memory-based scaling for any container |
| kedaAutoscaling.triggers.prometheus.activationThreshold | string | `""` | Activation threshold (optional) Minimum metric value to activate this scaler Prevents scaling from 0 on minimal load |
| kedaAutoscaling.triggers.prometheus.authModes | string | `"basic"` | Authentication mode for Victoria Metrics Options: "basic", "bearer", "tls" |
| kedaAutoscaling.triggers.prometheus.authentication | object | `{"kind":"ClusterTriggerAuthentication","name":"eni-keda-vmselect-creds"}` | Authentication configuration Reference to existing TriggerAuthentication or ClusterTriggerAuthentication resource - ClusterTriggerAuthentication: cluster-scoped resource that can be shared across namespaces - TriggerAuthentication: namespace-scoped resource (useful for namespace-restricted environments) |
| kedaAutoscaling.triggers.prometheus.authentication.kind | string | `"ClusterTriggerAuthentication"` | Authentication kind: "ClusterTriggerAuthentication" or "TriggerAuthentication" Use "TriggerAuthentication" for namespace-scoped environments Use "ClusterTriggerAuthentication" for cluster-wide shared credentials |
| kedaAutoscaling.triggers.prometheus.authentication.name | string | `"eni-keda-vmselect-creds"` | Name of the TriggerAuthentication or ClusterTriggerAuthentication resource This resource must be created separately and contain Victoria Metrics credentials Example ClusterTriggerAuthentication:   apiVersion: keda.sh/v1alpha1   kind: ClusterTriggerAuthentication   metadata:     name: eni-keda-vmselect-creds   spec:     secretTargetRef:     - parameter: username       name: victoria-metrics-secret       key: username     - parameter: password       name: victoria-metrics-secret       key: password  Example TriggerAuthentication (namespace-scoped):   apiVersion: keda.sh/v1alpha1   kind: TriggerAuthentication   metadata:     name: vmselect-creds     namespace: my-namespace   spec:     secretTargetRef:     - parameter: username       name: victoria-metrics-secret       key: username     - parameter: password       name: victoria-metrics-secret       key: password |
| kedaAutoscaling.triggers.prometheus.enabled | bool | `true` | Enable Prometheus/Victoria Metrics based scaling |
| kedaAutoscaling.triggers.prometheus.metricName | string | `"kong_request_rate"` | Metric name (used for identification in KEDA) |
| kedaAutoscaling.triggers.prometheus.query | string | `"sum(rate(kong_http_requests_total{ei_telekom_de_zone=\"{{ .Values.global.zone }}\",ei_telekom_de_environment=\"{{ .Values.global.environment }}\",app_kubernetes_io_instance=\"{{ .Release.Name }}-kong\"}[1m]))"` | PromQL query to execute Must return a single numeric value Can use Helm template variables (e.g., {{ .Values.global.zone }}) Example queries:   - Request rate: sum(rate(kong_http_requests_total{zone="zone1"}[1m]))   - Error rate: sum(rate(kong_http_requests_total{status=~"5.."}[1m])) |
| kedaAutoscaling.triggers.prometheus.serverAddress | string | `""` | Victoria Metrics server address (REQUIRED if enabled) Example: "http://prometheus.monitoring.svc.cluster.local:8427" Can use template variables: "{{ .Values.global.vmauth.url }}" |
| kedaAutoscaling.triggers.prometheus.threshold | string | `"100"` | Threshold value for the metric Scales up when query result exceeds this value For request rate: total requests/second across all pods |
| keyRotation.additionalSpecValues | object | `{}` | provide alternative configuration for cert-managers Certificate resource |
| keyRotation.enabled | bool | `false` | enable automatic cert / key rotation for access token issueing based on cert-manager and gateway-rotator |
| livenessProbe | object | `{"failureThreshold":4,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"periodSeconds":20,"timeoutSeconds":5}` | kong livenessProbe configuration |
| logFormat | string | `"json"` |  |
| memCacheSize | string | `"128m"` | Kong memory cache size for database entities |
| migrations | string | `"none"` | Determine the migrations behaviour for a new instance or upgrade |
| nginxHttpLuaSharedDict | string | `"prometheus_metrics 15m"` | Nginx HTTP Lua shared dictionary for storing metrics |
| nginxWorkerProcesses | int | `4` | Number of nginx worker processes |
| pdb.create | bool | `false` | enable pod discruption budget creation |
| pdb.maxUnavailable | string | `nil` | maxUnavailable pods in number or percent (defaults to 1 if unset and minAvailable also unset) |
| pdb.minAvailable | string | `nil` | minAvailable pods in number or percent |
| plugins.acl.pluginId | string | `"bc823d55-83b5-4184-b03f-ce63cd3b75c7"` | pluginId for configuration in kong |
| plugins.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for plugin containers |
| plugins.enabled | list | `["rate-limiting-merged"]` | additional enabled plugins for kong besides `bundled,jwt-keycloak` |
| plugins.jwtKeycloak.allowedIss | list | `["https://<your-iris-host>/auth/realms/rover"]` | The URL of the identity provider's rover realm. This is used for authenticating access to the Kong Admin API via the Rover realm |
| plugins.jwtKeycloak.enabled | bool | `true` | Activate or deactivate the jwt-keycloak plugin |
| plugins.jwtKeycloak.pluginId | string | `"b864d58b-7183-4889-8b32-0b92d6c4d513"` | pluginId for configuration in kong |
| plugins.prometheus.enabled | bool | `true` | Controls whether to annotate pods with prometheus scraping information or not |
| plugins.prometheus.path | string | `"/metrics"` | Sets the endpoint at which at which metrics can be accessed |
| plugins.prometheus.pluginId | string | `"3d232d3c-dc2b-4705-aa8d-4e07c4e0ff4c"` | pluginId for configuration in kong |
| plugins.prometheus.podMonitor.enabled | bool | `false` | Enables a podmonitor which can be used by the prometheus operator to collect metrics |
| plugins.prometheus.podMonitor.selector | string | `"guardians-raccoon"` | Default selector label for pod monitor |
| plugins.prometheus.port | int | `9542` | Sets the port at which metrics can be accessed |
| plugins.prometheus.serviceMonitor.enabled | bool | `true` | Enables a servicemonitor which can be used by the prometheus operator to collect metrics |
| plugins.prometheus.serviceMonitor.selector | string | `"guardians-raccoon"` | default selector label (only label) |
| plugins.requestSizeLimiting.enabled | bool | `true` |  |
| plugins.requestSizeLimiting.pluginId | string | `"1e199eee-f592-4afa-8371-6b61dcbd1904"` | pluginId for configuration in kong |
| plugins.requestTransformer.pluginId | string | `"e9fb4272-0aff-4208-9efa-6bfec5d9df53"` | pluginId for configuration in kong |
| plugins.zipkin.enabled | bool | `true` | Enable tracing via ENI-Zipkin-Plugin |
| plugins.zipkin.pluginId | string | `"e8ff1211-816f-4d93-9011-a4b194586073"` | pluginId for configuration in kong |
| podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsUser":100,"supplementalGroups":[1000]}` | Pod security context for Kong deployment (hardened defaults) |
| postgresql.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":999,"runAsNonRoot":true,"runAsUser":999}` | Container security context for PostgreSQL |
| postgresql.deployment.annotations | object | `{}` |  |
| postgresql.image | object | `{"repository":"postgresql","tag":"16.5"}` | PostgresQL image configuration (inherits global.image.registry and global.image.namespace) |
| postgresql.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for PostgreSQL container |
| postgresql.maxConnections | string | `"100"` | maximum number of client connections |
| postgresql.maxPreparedTransactions | string | `"0"` | maximum number of transactions that can be in the "prepared" state simultaneously setting this parameter to zero (default) disables the prepared-transaction feature |
| postgresql.persistence.keepOnDelete | bool | `false` |  |
| postgresql.persistence.mountDir | string | `"/var/lib/postgresql/data"` | Mount directory for PostgreSQL data |
| postgresql.persistence.resources | object | `{"requests":{"storage":"1Gi"}}` | Storage class name for PostgreSQL PVC (defaults to cluster default storage class if not set) storageClassName: "" |
| postgresql.podSecurityContext | object | `{"fsGroup":999,"supplementalGroups":[999]}` | Pod security context for PostgreSQL |
| postgresql.resources | object | `{"limits":{"cpu":"100m","memory":"500Mi"},"requests":{"cpu":"20m","memory":"200Mi"}}` | postgresql container default resource configuration |
| postgresql.sharedBuffers | string | `"32MB"` | memory dedicated to PostgreSQL for caching data |
| proxy.accessLog | string | `"/dev/stdout"` | Set the log target for access log |
| proxy.errorLog | string | `"/dev/stderr"` | Set the log target for error log |
| proxy.ingress.annotations | object | `{}` | Merges specific into global ingress annotations |
| proxy.ingress.enabled | bool | `true` | Create ingress for proxy |
| proxy.ingress.hosts[0].host | string | `"chart-example.local"` |  |
| proxy.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| proxy.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| proxy.ingress.tls | list | `[]` |  |
| proxy.tls.enabled | bool | `false` |  |
| readinessProbe | object | `{"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"timeoutSeconds":2}` | kong readinessProbe configuration |
| replicas | int | `1` | Number of Kong pod replicas (ignored when HPA, KEDA, or Argo Rollouts is enabled) |
| resources.limits.cpu | string | `"2500m"` |  |
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.cpu | int | `1` |  |
| resources.requests.memory | string | `"2Gi"` |  |
| setupJobs.activeDeadlineSeconds | int | `3600` | How long (in seconds) should be retried to run the job successfully |
| setupJobs.backoffLimit | int | `15` | How often should be retried to run the job successfully |
| setupJobs.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":100}` | Container security context for setup jobs |
| setupJobs.resources | object | `{"limits":{"cpu":0.5,"memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | resource defaults configured for the setupJobs |
| ssl | object | `{"cipherSuite":"custom","ciphers":"DHE-DSS-AES128-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES128-CCM:DHE-RSA-AES256-CCM:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-CCM:ECDHE-ECDSA-AES256-CCM:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_SHA256","protocols":"TLSv1.2 TLSv1.3"}` | Name of the secret containing the default server certificates defaultTlsSecret: "mysecret" |
| sslVerify | bool | `false` | Controls whether to check forward proxy traffic against CA certificates |
| sslVerifyDepth | string | `"1"` | SSL Verification depth |
| startupProbe | object | `{"failureThreshold":295,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":1,"timeoutSeconds":1}` | kong startupProbe configuration |
| strategy | object | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}` | Deployment strategy configuration |
| templateChangeTriggers | list | `[]` | List of (template) yaml files fo which a checksum annotation will be created |
| topologyKey | string | `"kubernetes.io/hostname"` | Topology key for pod anti-affinity (spread pods across zones for high availability) |
| workerConsistency | string | `"eventual"` | Kong worker consistency mode (eventual or strict) |
| workerStateUpdateFrequency | int | `10` | Frequency in seconds to poll for worker state updates |

## Troubleshooting

If the Gateway deployment fails to come up, please have a look at the logs of the container.

**Log message:**

```
Error: /usr/local/share/lua/5.1/opt/kong/cmd/start.lua:37: nginx configuration is invalid (exit code 1):
nginx: [emerg] SSL_CTX_load_verify_locations("/usr/local/opt/kong/tif/trusted-ca-certificates.pem") failed (SSL: error:0B084088:x509 certificate routines:X509_load_cert_crl_file:no certificate or crl found)
nginx: configuration file /opt/kong/nginx.conf test failed
```

**Solution:** 
This error happens if `sslVerify` is set to true but no valid certificates could be found. 
Please make sue that `trustedCaCertificates` is set probably or set sslVerify to false if you don't wish to use ssl verification.

## Compatibility

| Environment | Compatible |
| ----------- | ---------- |
| OTC         | Yes        |
| AppAgile    | Unverified |
| AWS EKS     | Yes        |
| CaaS        | Yes        |

This Helm Chart is also compatible with Sapling, DHEI's universal solution for deploying Helm Charts to multiple Telekom cloud platforms.
