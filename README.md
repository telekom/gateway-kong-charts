<!--
SPDX-FileCopyrightText: 2023 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0    
-->

# StarGate Helm Chart

**Table of contents**

[[_TOC_]]

## Code of Conduct

This project has adopted the [Contributor Covenant](https://www.contributor-covenant.org/) in version 2.1 as our code of conduct. Please see the details in our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). All contributors must abide by the code of conduct.

By participating in this project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Licensing

This project follows the [REUSE standard for software licensing](https://reuse.software/).
Each file contains copyright and license information, and license texts can be found in the [./LICENSES](./LICENSES) folder. For more information visit https://reuse.software/.


## Requirements

### Database

StarGate requires a PostgreSQL database that will be preconfigured by StarGate's init container.

## Configuration

### Platform

You can select a platform (e.g. caas) to use predefined settings (e.g. securityContext) specifically dedicated to the platform. \
Note that you can overwrite platform specific values in the values.yaml. \
To add a new platform specific values.yaml, add the required values as platforName.yaml to the platforms folder.

**Note:** Setting platform specific values for the sub-chart by the platform specific platformName.yaml of your main-chart will not work, as the sub-chart platforms have precedence.

### Database

No detailed configuration is necessary. PostgreSQL will be deployed together with StarGate. You should change the default passwords!

### Routes, Services, etc. via job

If you want to add routes, services, etc. you can set specific curl command to deploy you preferc configuration.

### External access

StarGate can be accessed via created Ingress/Route. See the Parameters section for details.
By default, URLs will have the format `<Release.Name>[-<Suffix>]-<.Release.Namespace>.<.Values.global.domain>`.
Setting dedicated hostnames for an ingress will overwrite the created URL. The value set in `hostname` needs to be fully qualified, as `.Values.global.domain` will not be added automatically!

## Security

### Community Edition

Be aware that exposing the Admin-API for Community Edition can be dangerous, as the API is not protected by any RBAC. Thus it can be accessed by anyone having access to the API url. \
Therefore the Admin-API-Ingress is disabled. For Mor details see [External access](#External-access).

By default, we protect the Admin API via a dedicated service and route together with the jwt-keycloak. You need to add the used issuer.

### SSL Verification

If you enable SSL verification StarGate will try to verify all traffic against a bundle of trusted CA certificates which needs to be specified explicitely. 
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
If you deploy a new instance of StarGate, make sure migrations is set to `bootstrap`.

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

### To Version 5.x.x

Starting from version 5 and above the htpasswd needs to be generated and set manually. \
This is necessary as double encoded base64 secrets are not supported by Vault. \
See chapter [htpasswd](#htpasswd).

## htpasswd

You can create the htpasswd for admin user with Apache htpasswd tool.

**Prerequisit:** existing gatewayAdminApiKey for the deployment.

1. Execute the following statement: ```htpasswd -cb htpasswd admin gatewayAdminApiKey```
2. Look up the htpasswd file you've just created and copy its content into the desired secret. \
   Make sure no spaces or line breaks are copied.
3. Optional but recommended: check if htpasswd is valid: ```htpasswd -vb htpasswd admin gatewayAdminApiKey```
4. Deploy and check if setup jobs can access the Kong admin-api and also if amin-api is accessible via the admin-api-route.

## Advanced Features

During the operation of Stargate we discovered some issues that need some more advanced Kong or Kubernetes settings.
The following paragraph explains which helm-chart settings are responsible, how to use them and what effects they have.

### Autoscaling

In some environments, especially in AWS "prod", we use the autoscaler to update workload ressources.

The autoscaling ia documented [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).
(Since chart version `5.4.0` we use kubernetes API `autoscaling/v2`)
 
Following helm-chart variables controls the autoscaler properties for Stargate:

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

Stargate is fully operational only when both components Kong and Jumper are operational. This is especially important when deploying as "Rolling Update" in customer environments.
For this reason, each container deployed in stargate pod has its own settings for `readinessProbe`, `livenessProbe` and configurable initial delays.

The Probe-URLs are configured as follows:
- `http://localhost:8100/status` as readiness probe for Kong
- `http://localhost:8100/status` as liveness probe for Kong
- `http://localhost:808x/actuator/health/readiness` as readiness probe for each Jumper pod ("jumper", "jegacyJumper")
- `http://localhost:808x/actuator/health/liveness` as liveness probe for each Jumper pod ("jumper", "jegacyJumper")

The details for readiness and liveness probes cen be tuned by following values:

| Helm-Chart variable                        | Container    | Kubernetes setting                 | default value |
|--------------------------------------------|--------------|------------------------------------|---------------|
| startup.livenessProbe.initialDelay         | kong         | livenessProbe.initialDelaySeconds  | 5             |
| startup.readinessProbe.initialDelay        | kong         | readinessProbe.initialDelaySeconds | 5             |
| jumper.startup.readinessProbe.initialDelay | jumper       | livenessProbe.initialDelaySeconds  | 25            |
| jumper.startup.readinessProbe.initialDelay | jumper       | readinessProbe.initialDelaySeconds | 25            |
| jumper.startup.readinessProbe.initialDelay | legacyJumper | livenessProbe.initialDelaySeconds  | 25            |
| jumper.startup.readinessProbe.initialDelay | legacyJumper | readinessProbe.initialDelaySeconds | 25            |
|                                            |              |                                    |               |
| *not configurable yet*                     | *all cont.*  | ...Probe.timeoutSeconds            | 5             |
| *not configurable yet*                     | *all cont.*  | ...Probe.periodSeconds             | 10            |
| *not configurable yet*                     | *all cont.*  | ...Probe.successThreshold          | 1             |
| *not configurable yet*                     | kong         | ...Probe.failureThreshold          | 6             |
| *not configurable yet*                     | *all jumper* | ...Probe.failureThreshold          | 3             |


### Latency in Kong (chart 5.2.2)

With the default setting, Kong has the following problem: while Rover is doing larger updates via the Admin-API (keyword "Reconciller"),unacceptable latencies arise in Stargate runtime.

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

| Parameter                                           | Description                                                                                                                               | Default                               |
|-----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------|
| `global`                                            | Common values for all DHEI-Helm-Charts                                                                                                    |                                       |
| `global.platform`                                   | Determines where the chart will be deployed                                                                                               | `kubernetes`                          |
| `global.storageClassName`                           | Overwrites the setting determined by the platform                                                                                         | `gp2`                                 |
| `global.domain`                                     | URL for cluster external access set in Ingress/Route                                                                                      | `nil`                                 |
| `global.labels`                                     | Define global labels                                                                                                                      | `tif.telekom.de/group`                |
| `global.ingress.annotations`                        | Set annotations for all ingress, can be extended by ingress specific ones                                                                 | `nil`                                 |
| `global.ingress.ingressClassName`                   | Set ingressClassName for all ingress in the chart. Can overwritten by specific ingress settings. Tdi default is triton-ingress.           | `nil`                                 |
| `global.image.repository`                           | Set default repository for all images                                                                                                     | `mtr.devops.telekom.de`               |
| `global.image.organisation`                         | Set default organisation for all images                                                                                                   | `tif-public`                          |
| `global.image.force`                                | Replace repository/organisation also if image is set as custom  "image:" value                                                            | `false`                               |
| `global.database.location`                          | Specifiy if you want to deploy a PostgreSQL or use an external database                                                                   | `local`                               |
| `global.database.port`                              | Port of the database                                                                                                                      | `5432`                                |
| `global.database.database`                          | Name of the database                                                                                                                      | `kong`                                |
| `global.database.schema`                            | Name of the schema                                                                                                                        | `public`                              |
| `global.database.username`                          | Username for accessing the database                                                                                                       | `kong`                                |
| `global.database.password`                          | The users password                                                                                                                        | `changeme`                            |
| `global.tracing`                                    | Set generic tracing settings, will be used if not specified explicitly                                                                    | `Trace settings`                      |
| `global.tracing.collectorUrl`| URL of the Zipkin-Collector (e.g. Jaeger-Collector), http(s) mandatory                                                                                           | `http://guardians-drax-collector.skoll:9411/api/v2/spans`|
| `global.tracing.defaultServiceName`                 | Name of the service shown in e.g. Jaeger                                                                                                  | `stargate`                            |
| `global.tracing.sampleRatio`                        | How often to sample requests that do not contain trace ids. Set to 0 to turn sampling off, or to 1 to sample all requests.                | `1`                                   |
| `migrations`                                        | Determine the migrations behaviuor for a new instance or upgrade                                                                          | `none`                                |
| `adminApi.enabled`                                  | Create service for accessing Kong Admin API                                                                                               | `true`                                |
| `adminApi.tls.enabled`                              | Access Admin API via https instead of http                                                                                                | `false`                               |
| `adminApi.ingress.enabled`                          | Create ingress for Admin API. Default depends on Edition                                                                                  | CE: `false`<br/>EE: `true`            |
| `adminApi.ingress.hostname`                         | Set dedicated hostname for Admin API ingress (or route), overwrites global URL                                                            | `nil`                                 |
| `adminApi.ingress.annotations`                      | Merges specific into global ingress annotations                                                                                           | `nil`                                 |
| `adminApi.ingress.ingressClassName`                 | Set ingressClassName for the Admin API ingress                                                                                            | `nil`                                 |
| `adminApi.access_log`                               | Set the log target for access log                                                                                                         | `/dev/stdout`                         |
| `adminApi.ingress.annotations`                      | Set the log target for error log                                                                                                          | `/dev/stderr`                         |
| `proxy.ingress.enabled`                             | Create ingress for proxy                                                                                                                  | `true`                                |
| `proxy.ingress.hostname`                            | Set dedicated hostname for proxy ingress (or route), overwrites global URL                                                                | `nil`                                 |
| `proxy.ingress.ingressClassName`                    | Set ingressClassName for the proxy ingress                                                                                                | `nil`                                 |
| `proxy.ingress.annotations`                         | Merges specific into global ingress annotations                                                                                           | `ssl-passthrough`                     |
| `proxy.access_log`                                  | Set the log target for access log                                                                                                         | `/dev/stdout`                         |
| `proxy.ingress.annotations`                         | Set the log target for error log                                                                                                          | `/dev/stderr`                         |
| `configuration`                                     | Set a script to run after deployment for configuration of StarGate                                                                        | `default admin-api conf`              |
| `templateChangeTriggers`                            | List of (template) yaml files fo which a checksum annotation will be created                                                              | `[]`                                  |
| `sslVerify`                                         | Controls whether to check forward proxy traffic against CA certificates                                                                   | `false`                               |
| `sslVerifyDepth`                                    | SSL Verification depth                                                                                                                    | `1`                                   |
| `setupJobs.backoffLimit`                            | How often should be retried to run the job successfully                                                                                   | `20`                                  |
| `setupJobs.activeDeadlineSeconds`                   | How long should be retried to run the job successfully                                                                                    | `300`                                 |
| `zipkin.enabled`                                    | Enable tracing via ENI-Zipkin-Plugin                                                                                                      | `false`                               |
| `zipkin.collectorUrl`                               | URL of the Zipkin-Collector (e.g. Jaeger-Collector), http(s) mandatory                                                                    | `http://guardians-drax-collector.skoll:9411/api/v2/spans`|
| `zipkin.sampleRatio`                                | How often to sample requests that do not contain trace ids. Set to 0 to turn sampling off, or to 1 to sample all requests.                | `1`                                   |
| `zipkin.includeCredential`                          | Should the credential of the currently authenticated consumer be included in metadata sent to the Zipkin server?                          | `true`                                |
| `zipkin.defaultServiceName`                         | Name of the service shown in e.g. Jaeger                                                                                                  | `stargate`                            |
| `zipkin.luaSslTrustedCertificate`                   | CA certificate for the Zipkin-Collector-URL                                                                                               | `nil`                                 |
| `trustedCaCertificates`                             | CA certificates in PEM format (string)                                                                                                    | `nil`                                 |
| `defaultTlsSecret`                                  | Name of the secret containing the default server certificates                                                                             | `nil`                                 |
| `plugins.`                                          | This section contains all Kong plugins settings                                                                                           | `See the following plugins`           |
| `prometheus.enabled`                                | Controls whether to annotate pods with prometheus scraping information or not                                                             | `true`                                |
| `prometheus.port`                                   | Sets the port at which metrics can be accessed                                                                                            | `9542`                                |
| `prometheus.path`                                   | Sets the endpoint at which at which metrics can be accessed                                                                               | `/metrics`                            |
| `prometheus.podMonitor.enabled`                     | Enables a podmonitor which can be used by the prometheus operator to collect metrics                                                      | `false`                               |
| `prometheus.podMonitor.scheme`                      | HTTP scheme to use for scraping                                                                                                           | `http`                                |
| `prometheus.podMonitor.interval`                    | Interval at which metrics should be scraped                                                                                               | `15s`                                 |
| `prometheus.podMonitor.scrapeTimeout`               | Timeout after which the scrape of prometheus is ended                                                                                     | `3s`                                  |
| `prometheus.podMonitor.honorLabels`                 | HonorLabels chooses the metric’s labels on collisions with target labels                                                                  | `true`                                |
| `prometheus.serviceMonitor.enabled`                 | Enables a servicemonitor which can be used by the prometheus operator to collect metrics                                                  | `true`                                |
| `prometheus.serviceMonitor.scheme`                  | HTTP scheme to use for scraping                                                                                                           | `http`                                |
| `prometheus.serviceMonitor.interval`                | Interval at which metrics should be scraped                                                                                               | `15s`                                 |
| `prometheus.serviceMonitor.scrapeTimeout`           | Timeout after which the scrape of prometheus is ended                                                                                     | `3s`                                  |
| `prometheus.serviceMonitor.honorLabels`             | HonorLabels chooses the metric’s labels on collisions with target labels                                                                  | `true`                                |
| `jwtKeycloak.enabled`                               | Activate or deactivate the jwt-keycloak plugin                                                                                            | `true`                                |
| `jwtKeycloak.setupJob`                              | Set required values for the provieded configuration. Can be ignored for costum config                                                     |                                       |
| `jwtKeycloak.setupJob.pluginId`                     | If you want to alter the already configured plugin, set the pluginId                                                                      | `24f1d5a5-4d31-4abc-b539-bed6d3cd7f0a`|
| `jwtKeycloak.setupJob.allowedIss`                   | Set the Iris URL you want StarGate to use for Admin API athentication                                                                     | `https://changeme/auth/realms/default`|
| `jumper`                                            | Configure the Jumper (by Hyperion)                                                                                                        | `1.5.5`                               |
| `issuerService`                                     | Confgiure the Issuer-Service (by Hyperion)                                                                                                | `1.0.0`                               |
| `postgresql.image`                                  | Specifiy the PostgreSQL image                                                                                                             | `postgres-12.3-debian`                |
| `postgresql.securityContext`                        | Specifiy the security context                                                                                                             | `nil`                                 |
| `postgresql.resources`                              | Assign ressources, e.g. limits, for Postgres                                                                                              | `Memory limits`                       |
| `externalDatabase.host`                             | If an external database is used, this is the url of the database instance                                                                 | `nil`                                 |
| `externalDatabase.ssl`                              | Use ssl for connection                                                                                                                    | `false`                               |
| `externalDatabase.sslVerify`                        | Use the provided certificate                                                                                                              | `false`                               |
| `externalDatabase.luaSslTrustedCertificate`         | Provide certificate                                                                                                                       | `nil`                                 |
| `replicas`                                          | Set the number of Stargate replicas                                                                                                       | `1`                                   |
| `autoscaling.enabled`                               | Enables Pod Autoscaling with Target CPU usage                                                                                             | `false`                               |
| `autoscaling.minReplicas`                           | Minimum number of replicas if autoscaling is enabled                                                                                      | `$replicas`                           |
| `autoscaling.maxReplicas`                           | Maximum number of replicas if autoscaling is enabled                                                                                      | `10`                                  |
| `autoscaling.cpuUtilizationPercentage`              | Number of target CPU Utilization                                                                                                          | `80`                                  |
| `logFormat`                                         | Selects the mginx log format `default`, `json` or `plain`                                                                                 | `default`                             |

## Troubleshooting

If StarGate deployment fails to come up, please have a look at the logs of the container.

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
