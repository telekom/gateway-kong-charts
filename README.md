<!--
SPDX-FileCopyrightText: 2023 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0   
-->

# Gateway Helm Chart

## Code of Conduct

This project has adopted the [Contributor Covenant](https://www.contributor-covenant.org/) in version 2.1 as our code of conduct. Please see the details in our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). All contributors must abide by the code of conduct.

By participating in this project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Licensing

This project follows the [REUSE standard for software licensing](https://reuse.software/).
Each file contains copyright and license information, and license texts can be found in the [./LICENSES](./LICENSES) folder. For more information visit https://reuse.software/.

## Requirements

### Database

This Gateway requires a PostgreSQL database that will be preconfigured by the Gateway's init container.

## Configuration

### Platform

You can select a platform (e.g. caas) to use predefined settings (e.g. securityContext) specifically dedicated to the platform. \
Note that you can overwrite platform specific values in the values.yaml. \
To add a new platform specific values.yaml, add the required values as platforName.yaml to the platforms folder.

**Note:** Setting platform specific values for the sub-chart by the platform specific platformName.yaml of your main-chart will not work, as the sub-chart platforms have precedence.

### Database

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
You can enable this by setting sslVerify to true in the ``values.yaml``.  If you do so, you must provide your own truststore by setting the ``trustedCaCertificates`` field with the content of your CA certificates in PEM format otherwise Kong won't start.

Example *values.yaml*:
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
Of course Helm let's you reference multiple values files when installing a deployment so you could also outsource ``trustedCaCertificates`` wo its own values file, for example ``my-trustes-ca-certificates.yaml``.

### Supported TLS versions

Only TLS versions TLSv1.2 and TLSv.1.3 are allowed. TLSv1.1 is NOT supported.

### Server Certificate

If "https" is used but no SNI is configured, the API gateway provides a default server certificate issued for "https://localhost". You can replace the default certificate by a custom server-certificate by specyfing the secret name in the variable ``defaultTlsSecret``.

Example *values.yaml*:
```yaml
defaultTlsSecret: my-https-secret
```

Here are some examples how to create a corresponding secret from PEM files. For more details s. Kubernetes documentation.
```
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

**Note:** Those jobs are only ment to be used for upgrading.

## Upgrade Advice
The following section contains special advice for dedicated updates and maybe necessary steps to be taken if updating from a certain version to another.
Although updates in minor versions, whilst keeping the same major verison, do not contain breaking changes, implications may occour.

### To 1.24.0 and up
This version introduces Kong 2.8.1 and requires migrations to be run.\
It also requires to adapt to the changed ```securityContext``` settings of the ```plugins``` in the ````values.yaml```. 

### To 1.23.0 and up
Version 1.23.0 introduces a new issuer service version. If in use, this requires to set values for the new secret ```secret-issuer-service.yml```. \
Replace ```jsonWebKey: changeme``` and  ```publicKey: changeme```.

### From 1.5.x and lower to 1.6.x
With introduction of Kong CE, a dedicated Admin-API handling has been introduced to proted the Admin-API. This required changes to the ingress of the Admin-API.
Those changes are only reflected in the ```ingress-admin.yml``` and not in the ```route-admin.yml```. Using Kong CE will work, but deploying
the Admin-API-Route will provide unsecured access to the Admin-API.

### From 1.7.x and lower to 1.8.x and up
The bundled Zipkin-plugin has been replaced by the ENI-Zipkin pluging. Behaviour and configuration differ slightly to the used one.
To avoid complications, we strongly recommend removing the existing Zipkin-Plugin before upgrading. This can be done via a DELETE call on the Admin-API (Token required).

Lookup all plugins and find the Zipkin-Plugin-ID:
```
via GET on https://admin-api-url.me/plugins
```
Deleting the existing plugin:
```
via DELETE on https://admin-api-url.me/plugins/<zipkinPluginId>
```

### From 2.x.x and lower to 3.x.x
We changed the integration of the ENI-plugins. Therefore names of the plugins changed and and eni-prefixed plugins have been removed from the image. Therefore the configuration of Kong itself, precisely the database, needs to be updated.
You can do this by activating the jobs migration. This will delete the "old" ENI-plugins to allow the configuration of the new ones.

```
migrations: jobs
```
### From 2.x.x and lower to 4.x.x
The migration from 2.x.x to 4.x.x is not possible. Please upgrade first from 2.x.x to 3.x.x as described above and afterwards without any migrations configuration from 3.x.x to 4.x.x

### From 4.x.x to Version 5.x.x

Starting from version 5 and above the htpasswd needs to be generated and set manually. \
This is necessary as double encoded base64 secrets are not supported by Vault. \
See chapter [htpasswd](#htpasswd).

### From 5.x.x to Version 6.x.x ( :warning: !Breaking Change! :warning: )

#### Ingress config definition changes

We streamlined the ingress configurations to be more capable of handling multiple hostnames. Additionally we aligned the configuration options according best practices in helm charts in general.

Before your ingress configuration might have looked like this:

```yaml
proxy:
  ingress:
    hostname: stargate.telekom.de
    altHostname: stargate-alternative.telekom.de
    tlsSecret: my-provided-secret
adminApi:
  ingress:
    hostname: stargate.telekom.de
    altHostname: stargate-alternative.telekom.de
    tlsSecret: my-provided-secret
```

Now it looks like this:

```yaml
proxy:
  ingress:
    className: nginx-ingress
    hosts:
      - host: stargate.telekom.de
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
          - stargate.telekom.de
adminApi:
  ingress:
    className: nginx-ingress
    hosts:
      - host: admin-api.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
          - admin-api.example.com
```

This allows a more flexible configuration of the ingress and most importantly allows to add multiple hosts with different tls secrets linked to them. Please pay attention that the properties and the corresponding functionality of `proxy.tls.enabled` as well as `adminApi.tls.enabled` are not touched by this change.

### From 6.x.x To Version 7.x.x ( :warning: !Breaking Change! :warning: )

#### Health probe configurations

If you have specific adjust helm values to reconfigure the health probes of the chart, take a look to the new clean way of configuring those. We do not have any specific variables for the probes anymore and we rely on kubernetes defaults more.

In our deployments we just render the yaml values as defined in the values.yaml. The default for this specific probe from values.yaml is the following:

```yaml
livenessProbe:
  httpGet:
    path: /status
    port: status
    scheme: HTTP
  timeoutSeconds: 5
  periodSeconds: 20
  failureThreshold: 4
```

#### certificate changes

The following configuration is now obsolete. The corresponding Secret is not rendered anymore.

```yaml
issuerService:
  certsJson: changeme
  publicJson: changeme
  privateJson: changeme
```

There are now two options of prodiving a secret to enable a smooth rotation of private/public keys and certificates.

1. Use `keyRotation.enabled=true` to provide manifests for an automatic rotation. This needs a running cert-manager as well as a running [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process)
2. Provide own secrets and reference them with setting `jumper.existingJwkSecretName` and `issuerService.existingJwkSecretName`. The secrets have to be identical and be conform to the format described in the [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process)

For more information about the certificate rotation please refer to the [cert-manager](https://cert-manager.io/docs/) documentation as well as the documentation of the [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process).

## htpasswd

You can create the htpasswd for admin user with Apache htpasswd tool.

**Prerequisit:** existing gatewayAdminApiKey for the deployment.

1. Execute the following statement: ```htpasswd -cb htpasswd admin gatewayAdminApiKey```
2. Look up the htpasswd file you've just created and copy its content into the desired secret. \
   Make sure no spaces or line breaks are copied.
3. Optional but recommended: check if htpasswd is valid: ```htpasswd -vb htpasswd admin gatewayAdminApiKey```
4. Deploy and check if setup jobs can access the Kong admin-api and also if amin-api is accessible via the admin-api-route.

## Advanced Features

During the operation of the Gateway we discovered some issues that need some more advanced Kong or Kubernetes settings.
The following paragraph explains which helm-chart settings are responsible, how to use them and what effects they have.

### Autoscaling

In some environments, especially in AWS "prod", we use the autoscaler to update workload ressources.

The autoscaling ia documented [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).
(Since chart version `5.4.0` we use kubernetes API `autoscaling/v2`)

Following helm-chart variables controls the autoscaler properties for the Gateway:

| Helm-Chart variable                    | Kubernetes property (HorizontalPodAutoscaler)     | default value | documentation link |
|----------------------------------------|---------------------------------------------------|---------------|--------------------|
| `autoscaling.enabled`                  |                                                   | false         |                    |
| `autoscaling.minReplicas`              | `spec.minReplicas`                                | 3             | [k8s_hpe_spec]     |
| `autoscaling.maxReplicas`              | `spec.maxReplicas`                                | 10            | [k8s_hpe_spec]     |
| `autoscaling.cpuUtilizationPercentage` | `spec.metrics.resource.target.averageUtilization` | 80            | [k8s_hpe_spec]     |

[k8s_hpe_spec]: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/#HorizontalPodAutoscalerSpec

### PodAntiaffinity & TopologyKey

In Kubernetes it is recommended to distribute the pods over several nodes. If a kubernetes node gets into problems, there are enough pods on other nodes to take on the load.
For this reason we provide the `topologyKey` flag in our helm-chart.

| Helm-Chart variable | Kubernetes property (Deployment,Pod)        | default value                        | documentation link |
|---------------------|---------------------------------------------|--------------------------------------|--------------------|
| `topologyKey`       | `spec.affinity.podAntiAffinity.topologyKey` | kubernetes.io/hostname **AWS**       | [topologyKey]      |
| `topologyKey`       | `spec.affinity.podAntiAffinity.topologyKey` | topology.kubernetes.io/zone **CaaS** | [topologyKey]      |

[topologyKey]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity

> Note: The default topologyKey for CaaS is different than for AWS and is specified in `platform/caas.yaml` (s. next paragraph)

### Platform-specific values and SecurityContext

CaaS platform has certain requirements regarding `securityContext` in deployments.
Some fields like `privileged: false` must be set, even though they correspond to the default values.
This applies to both `pods.securityContext` and `container[].securityContext` and the absence of some values is difficult to detect, because CaaS refuses the deployment with a 503 http-code.

For this reason, there is one single flags `global.platform: caas`, which imports values from file `platform/caas.yaml` and thus applies all required to the deployment.
Individual values can be overwritten as usual.

The same approach can be used to extend the helm-chart for other platforms.

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

| Component         | Helm values for health probe configs                                                      |
|-------------------|-------------------------------------------------------------------------------------------|
| `kong`            | `readinessProbe`,`livenessProbe`,`startupProbe`                                           |
| `jumper`          | `jumper.readinessProbe`,`jumper.livenessProbe`,`jumper.startupProbe`                      |
| `issuer-service`  | `issuerService.readinessProbe`,`issuerService.livenessProbe`,`issuerService.startupProbe` |

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
|----------------------------|------------------------------------|---------------|---------------------------------|
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
| autoscaling.enabled | bool | `false` |  |
| circuitbreaker.enabled | bool | `false` | enable deployment of circuitbreaker component |
| circuitbreaker.imagePullPolicy | string | `"IfNotPresent"` | default value for imagePullPolicy |
| circuitbreaker.resources | object | `{"limits":{"cpu":0.5,"memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | circuitbreaker container default resource configuration |
| disableUpstreamCache | bool | `false` |  |
| externalDatabase.ssl | bool | `true` |  |
| externalDatabase.sslVerify | bool | `false` |  |
| global.database.database | string | `"kong"` | Name of the database |
| global.database.location | string | `"local"` | Determine if the a database will be deployed togehter with Stargate (local) or is provided (external) |
| global.database.password | string | `"changeme"` | The users password |
| global.database.schema | string | `"public"` | Name of the schema |
| global.database.username | string | `"kong"` | Username for accessing the database |
| global.failOnUnsetValues | bool | `true` |  |
| global.image.force | bool | `false` | Replace repository/organisation also if image is set as custom  "image:" value |
| global.imagePullPolicy | string | `"IfNotPresent"` | global default for imagePullPolicy |
| global.imagePullSecrets | string | `nil` | array of pull secret names to use for image pulling |
| global.ingress.annotations | object | `{}` | Set annotations for all ingress, can be extended by ingress specific ones |
| global.labels | object | `{"tardis.telekom.de/group":"tardis"}` | Define global labels |
| global.metadata.pipeline | object | `{}` |  |
| global.passwordRules.enabled | bool | `false` |  |
| global.passwordRules.length | int | `12` |  |
| global.passwordRules.mustMatch[0] | string | `"[a-z]"` |  |
| global.passwordRules.mustMatch[1] | string | `"[A-Z]"` |  |
| global.passwordRules.mustMatch[2] | string | `"[0-9]"` |  |
| global.passwordRules.mustMatch[3] | string | `"[^a-zA-Z0-9]"` |  |
| global.platform | string | `"kubernetes"` | Available platforms: kubernetes (default), aws, caas. Setting any value with no specific platform values.yaml will result in fallback to kubernetes |
| global.podAntiAffinity.required | bool | `false` | configure pod anti affinity to be requiredDuringSchedulingIgnoredDuringExecution or preferredDuringSchedulingIgnoredDuringExecution |
| global.preStopSleepBase | int | `30` |  |
| global.product | string | `"stargate"` |  |
| global.tracing.collectorUrl | string | `"http://guardians-drax-collector.skoll:9411/api/v2/spans"` | URL of the Zipkin-Collector (e.g. Jaeger-Collector), http(s) mandatory |
| global.tracing.defaultServiceName | string | `"stargate"` | Name of the service shown in e.g. Jaeger |
| global.tracing.sampleRatio | int | `1` | How often to sample requests that do not contain trace ids. Set to 0 to turn sampling off, or to 1 to sample all requests. |
| global.zone | string | `"zoneName"` | Overwrites the setting determined by the platform storageClassName: gp2 environment: "" |
| irixBrokerRoute.enabled | bool | `false` |  |
| irixBrokerRoute.name | string | `"user-login"` |  |
| irixBrokerRoute.upstream.path | string | `"/auth/realms/eni-login"` |  |
| irixBrokerRoute.upstream.port | int | `80` |  |
| irixBrokerRoute.upstream.protocol | string | `"http"` |  |
| irixBrokerRoute.upstream.service | string | `"irix-broker"` |  |
| issuerService.enabled | bool | `true` | enable deployment of issuer-service container inside gateway pod |
| issuerService.environment | list | `[]` | generic injection possibility for additional environment variables - {name: foo, value: bar} |
| issuerService.existingJwkSecretName | string | `nil` | configure manually externally managed secret for oauth (as alternative for keyRotation.enabled=true)  |
| issuerService.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"timeoutSeconds":5}` | issuerService livenessProbe configuration |
| issuerService.readinessProbe | object | `{"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"}}` | issuerService readinessProbe configuration |
| issuerService.resources | object | `{"limits":{"cpu":"500m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | issuerService container default resource configuration |
| issuerService.startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health","port":"issuer-service","scheme":"HTTP"},"periodSeconds":1}` | issuerService startupProbe configuration |
| job | object | `{}` |  |
| jobs | object | `{}` |  |
| jumper.enabled | bool | `true` | enable deployment of jumper conatiner inside gateway pod |
| jumper.environment | list | `[]` | generic injection possibility for additional environment variables - {name: foo, value: bar} |
| jumper.existingJwkSecretName | string | `nil` | configure manually externally managed secret for oauth access token issueing (as alternative for keyRotation.enabled=true)  |
| jumper.internetFacingZones | list | `[]` | list of zones that are considered internet facing |
| jumper.issuerUrl | string | `"https://localhost:443"` |  |
| jumper.jvmOpts | string | `"-XX:MaxRAMPercentage=75.0 -XshowSettings:vm"` |  |
| jumper.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/actuator/health/liveness","port":"jumper","scheme":"HTTP"},"timeoutSeconds":5}` | jumper livenessProbe configuration |
| jumper.publishEventUrl | string | `"http://producer.integration:8080/v1/events"` |  |
| jumper.readinessProbe | object | `{"httpGet":{"path":"/actuator/health/readiness","port":"jumper","scheme":"HTTP"},"initialDelaySeconds":5}` | jumper readinessProbe configuration |
| jumper.resources | object | `{"limits":{"cpu":5,"memory":"1500Mi"},"requests":{"cpu":2,"memory":"1Gi"}}` | jumper container default resource configuration |
| jumper.stargateUrl | string | `"https://stargate-integration.test.dhei.telekom.de"` |  |
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
| keyRotation.additionalSpecValues | object | `{}` | provide alternative configuration for cert-managers Certificate resource |
| keyRotation.enabled | bool | `false` | enable automatic cert / key rotation for access token issueing based on cert-manager and gateway-rotator |
| livenessProbe | object | `{"failureThreshold":4,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"periodSeconds":20,"timeoutSeconds":5}` | kong livenessProbe configuration |
| logFormat | string | `"json"` |  |
| migrations | string | `"none"` | Determine the migrations behaviour for a new instance or upgrade |
| pdb.create | bool | `false` | enable pod discruption budget creation |
| pdb.maxUnavailable | string | `nil` | maxUnavailable pods in number or percent (defaults to 1 if unset and minAvailable also unset) |
| pdb.minAvailable | string | `nil` | minAvailable pods in number or percent |
| plugins.acl.pluginId | string | `"bc823d55-83b5-4184-b03f-ce63cd3b75c7"` | pluginId for configuration in kong |
| plugins.enabled | list | `["rate-limiting-merged"]` | additional enabled plugins for kong besides `bundled,jwt-keycloak` |
| plugins.jwtKeycloak.allowedIss | list | `["https://changeme/auth/realms/default"]` | Set the Iris URL you want the Gateway to use for Admin API athentication |
| plugins.jwtKeycloak.enabled | bool | `true` | Activate or deactivate the jwt-keycloak plugin |
| plugins.jwtKeycloak.pluginId | string | `"b864d58b-7183-4889-8b32-0b92d6c4d513"` | pluginId for configuration in kong |
| plugins.prometheus.enabled | bool | `true` | Controls whether to annotate pods with prometheus scraping information or not |
| plugins.prometheus.path | string | `"/metrics"` | Sets the endpoint at which at which metrics can be accessed |
| plugins.prometheus.pluginId | string | `"3d232d3c-dc2b-4705-aa8d-4e07c4e0ff4c"` | pluginId for configuration in kong |
| plugins.prometheus.podMonitor.enabled | bool | `false` | Enables a podmonitor which can be used by the prometheus operator to collect metrics |
| plugins.prometheus.port | int | `9542` | Sets the port at which metrics can be accessed |
| plugins.prometheus.serviceMonitor.enabled | bool | `true` | Enables a servicemonitor which can be used by the prometheus operator to collect metrics |
| plugins.prometheus.serviceMonitor.selector | string | `"guardians-raccoon"` | default selector label (only label) |
| plugins.requestSizeLimiting.enabled | bool | `true` |  |
| plugins.requestSizeLimiting.pluginId | string | `"1e199eee-f592-4afa-8371-6b61dcbd1904"` | pluginId for configuration in kong |
| plugins.requestTransformer.pluginId | string | `"e9fb4272-0aff-4208-9efa-6bfec5d9df53"` | pluginId for configuration in kong |
| plugins.zipkin.enabled | bool | `true` | Enable tracing via ENI-Zipkin-Plugin |
| plugins.zipkin.pluginId | string | `"e8ff1211-816f-4d93-9011-a4b194586073"` | pluginId for configuration in kong |
| postgresql.resources | object | `{"limits":{"cpu":"100m","memory":"500Mi"},"requests":{"cpu":"20m","memory":"200Mi"}}` | postgresql container default resource configuration |
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
| replicas | int | `1` |  |
| resources.limits.cpu | string | `"2500m"` |  |
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.cpu | int | `1` |  |
| resources.requests.memory | string | `"2Gi"` |  |
| setupJobs.resources | object | `{"limits":{"cpu":0.5,"memory":"500Mi"},"requests":{"cpu":"50m","memory":"200Mi"}}` | resource defaults configured for the setupJobs |
| ssl | object | `{"cipherSuite":"custom","ciphers":"DHE-DSS-AES128-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES128-CCM:DHE-RSA-AES256-CCM:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-CCM:ECDHE-ECDSA-AES256-CCM:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_SHA256","protocols":"TLSv1.2 TLSv1.3"}` | Name of the secret containing the default server certificates defaultTlsSecret: "mysecret" |
| sslVerify | bool | `false` | Controls whether to check forward proxy traffic against CA certificates |
| sslVerifyDepth | string | `"1"` | SSL Verification depth |
| startupProbe | object | `{"failureThreshold":295,"httpGet":{"path":"/status","port":"status","scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":1,"timeoutSeconds":1}` | kong startupProbe configuration |
| strategy | object | `{}` |  |
| templateChangeTriggers | list | `[]` | List of (template) yaml files fo which a checksum annotation will be created |

## Troubleshooting

If the Gateway deployment fails to come up, please have a look at the logs of the container.

**Log message:**
```
Error: /usr/local/share/lua/5.1/opt/kong/cmd/start.lua:37: nginx configuration is invalid (exit code 1):
nginx: [emerg] SSL_CTX_load_verify_locations("/usr/local/opt/kong/tif/trusted-ca-certificates.pem") failed (SSL: error:0B084088:x509 certificate routines:X509_load_cert_crl_file:no certificate or crl found)
nginx: configuration file /opt/kong/nginx.conf test failed
```
**Solution:** 
This error happens if ``sslVerify`` is set to true but no valid certificates could be found. 
Please make sue that ``trustedCaCertificates`` is set probably or set sslVerify to false if you don't wish to use ssl verification.

## Compatibility

| Environment | Compatible |
|-------------|------------|
| OTC         | Yes        |
| AppAgile    | Unverified |
| AWS EKS     | Yes        |
| CaaS        | Yes        |

This Helm Chart is also compatible with Sapling, DHEI's universal solution for deploying Helm Charts to multiple Telekom cloud platforms.
