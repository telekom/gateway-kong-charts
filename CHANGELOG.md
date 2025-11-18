# Changelog

Please refer to the README for additional upgrade instructions.


## [8.1.8](https://github.com/telekom/gateway-kong-charts/compare/8.1.7...8.1.8) (2025-11-18)


### Bug Fixes

* upgrade gateway-jumper to default 4.2.5 ([bd351b0](https://github.com/telekom/gateway-kong-charts/commit/bd351b0e3c23f17c4310c612130cea454016b30a))

## [8.1.7](https://github.com/telekom/gateway-kong-charts/compare/8.1.6...8.1.7) (2025-11-14)


### Bug Fixes

* add guidance for Argo Rollouts initial takeover and update examples ([259a764](https://github.com/telekom/gateway-kong-charts/commit/259a7642b3b351bb151c55c12c976b4792f984c0))

## [8.1.6](https://github.com/telekom/gateway-kong-charts/compare/8.1.5...8.1.6) (2025-11-13)


### Bug Fixes

* bump default gateway-kong-image to 1.2.1 ([063ff52](https://github.com/telekom/gateway-kong-charts/commit/063ff52002ae5bcd8905ad2811ccc255684b7eda))

## [8.1.5](https://github.com/telekom/gateway-kong-charts/compare/8.1.4...8.1.5) (2025-11-13)


### Bug Fixes

* enable canary dynamicStableScale per default ([e8a9acb](https://github.com/telekom/gateway-kong-charts/commit/e8a9acbeb35e57d41db8a7d54fd4f706bacbeb10))

## [8.1.4](https://github.com/telekom/gateway-kong-charts/compare/8.1.3...8.1.4) (2025-11-13)


### Bug Fixes

* make Argo Rollouts scaleDown strategy configurable ([e20897c](https://github.com/telekom/gateway-kong-charts/commit/e20897c32455ee87f3890914d0430968f1cb299f))

## [8.1.3](https://github.com/telekom/gateway-kong-charts/compare/8.1.2...8.1.3) (2025-11-12)


### Bug Fixes

* increase memory utilization threshold for KEDA autoscaling ([7f43e64](https://github.com/telekom/gateway-kong-charts/commit/7f43e649c62a3e02c29f59b4874e536bbdda1ffb))
* set replicas to 0 when autoscaling is enabled ([00b22db](https://github.com/telekom/gateway-kong-charts/commit/00b22dba0845152b9edb3779a8948be9023d8874))

## [8.1.2](https://github.com/telekom/gateway-kong-charts/compare/8.1.1...8.1.2) (2025-11-10)


### Bug Fixes

* upgrade gateway-jumper to default 4.2.4 ([63c925d](https://github.com/telekom/gateway-kong-charts/commit/63c925de6fd0ab19139fc3913d7875ea596b9843))

## [8.1.1](https://github.com/telekom/gateway-kong-charts/compare/8.1.0...8.1.1) (2025-11-10)


### Bug Fixes

* keda reference to enabled rollouts for scaling ([b34574f](https://github.com/telekom/gateway-kong-charts/commit/b34574f1cdf0ac1246cfe2afbdc01a40b159d188))
* set default canary time to 5 minutes to give metrics more time ([534adf5](https://github.com/telekom/gateway-kong-charts/commit/534adf52e10106f15c313bdfe10a46566138522d))
* use role labels for querying rollouts analysis template + improved template args for metrics ([2115837](https://github.com/telekom/gateway-kong-charts/commit/2115837783bd78c373c98e29b4681f9628f8f014))

# [8.1.0](https://github.com/telekom/gateway-kong-charts/compare/8.0.0...8.1.0) (2025-11-03)


### Features

* introduce argo rollouts ([731a6f6](https://github.com/telekom/gateway-kong-charts/commit/731a6f63c2ddc68bb4977a5cd343ababc9d64f72))

# [8.0.0](https://github.com/telekom/gateway-kong-charts/compare/7.4.3...8.0.0) (2025-10-27)


### Bug Fixes

* make db port configurable for bootstrap and migration jobs ([aa814d3](https://github.com/telekom/gateway-kong-charts/commit/aa814d3da96a4fbd9af5a16e2572363283950102))


### Features

* upgrade chart template and nginx configuration for kong 3.9.1 migration ([#8](https://github.com/telekom/gateway-kong-charts/issues/8)) ([7553607](https://github.com/telekom/gateway-kong-charts/commit/755360772092336366f45870f062c6fe2cc8db81)), closes [#DHEI-18702](https://github.com/telekom/gateway-kong-charts/issues/DHEI-18702)


### BREAKING CHANGES

* This version upgrades to gateway-kong-image 1.1.0 using kong 3.9.1

* feat: upgrade chart template and nginx configuration to match kong 3.9.1
* chore: use gateway_consumer in nginx_kong plugin
* fix: use gateway_consumer from kong.ctx.shared
* feat: remove nginx-kong-template from chart
* fix: add podSecurityContext for migrations jobs
* fix: new jumper w java 21 auto picks up this env var
* feat: jumper 4.2.1 introduction as default
* fix: bump jumper to 4.2.2
* feat: switch to kong build 1.1.0 with kong 3.9.1
* feat: add keda autoscaling
  - Add KEDA ScaledObject template with per-container CPU/memory triggers
  - Add Prometheus/Victoria Metrics trigger support
  - Add cron-based scaling support
  - Configure HPA behavior policies for scale-up/down
  - Move HPA config from `autoscaling` to `hpaAutoscaling`

## [7.4.3](https://github.com/telekom/gateway-kong-charts/compare/7.4.2...7.4.3) (2025-08-22)


### Bug Fixes

* update jumper to 4.1.4 (switch to nonroot image) ([0e2901d](https://github.com/telekom/gateway-kong-charts/commit/0e2901d465df8a10759a528dd9952634550d92ce))

## [7.4.2](https://github.com/telekom/gateway-kong-charts/compare/7.4.1...7.4.2) (2025-08-22)


### Bug Fixes

* update jumper to 4.1.3 (switch to google distroless image) ([418955d](https://github.com/telekom/gateway-kong-charts/commit/418955d2cecbdbd5e0fe3bede7ac472c7166c93e))

## [7.4.1](https://github.com/telekom/gateway-kong-charts/compare/7.4.0...7.4.1) (2025-08-15)


### Bug Fixes

* update issuer image v2.2.0 -> v2.2.1 ([cc0284b](https://github.com/telekom/gateway-kong-charts/commit/cc0284bca1d8adf841f67c23ef0a8fc88d9f402f))

# [7.4.0](https://github.com/telekom/gateway-kong-charts/compare/7.3.2...7.4.0) (2025-08-11)


### Features

* update issuer service to v2.2.0 making ISSUER_URL environment variable obsolete ([d9dfded](https://github.com/telekom/gateway-kong-charts/commit/d9dfded8b1d65cc2f642d3b35134d1034eb61be4))

## [7.3.2](https://github.com/telekom/gateway-kong-charts/compare/7.3.1...7.3.2) (2025-08-06)


### Bug Fixes

* update default jumper image to 4.1.2 built on github ([ac8cae6](https://github.com/telekom/gateway-kong-charts/commit/ac8cae6442f1fe55276d2b50d343438063052610))

## 7.3.1
- fix: correct pdb label selector

## 7.3.0
- feat: add PDB for kong

## 7.2.1
- fix: switch to open source [gateway-kong-image](https://github.com/telekom/gateway-kong-image) based on Kong 2.8.3

## 7.2.0
- feat: remove unused cequence plugin functionality
- feat: remove deprecated legacy-jumper
- feat: update issuer-service to 2.1.1

## 7.1.0
- feat: added configurable internet facing zone names for jumper
- jumper 4.1.0 needed

## 7.0.2
- fix: value names for logging in kong

## 7.0.1
- make jwt issuer secrets mandatory for deployment volumes

## 7.0.0
- :warning: !breaking: Switched to new secret format to enable graceful cert/key rotation for oauth mechanisms
- jumper 4.0.0 needed
- new issuer-service-go 2.0.1 as default (see https://github.com/telekom/gateway-issuer-service-go) with corresponding changed defaults

## 6.0.0
- :warning: !breaking: refactor ingress definitions and align to defaults / best practices (needs reconfiguring ingress values in existing deployments)

## 5.5.4
- Plugin configuration for rate-limiting-merged is no longer hardcoded

## 5.5.3
- jumper 3.19.1
  - en/decoding for tracing as well as splitting query params manually
  
## 5.5.2
- jumper 3.19.0
  - adjust config to hide sig param in sleuth tracing

## 5.5.1
- Change from Ingress Class Annotation to ingressClassName field (aws only)

## 5.5.0
- Increased RequestSizeLimit to 10MB

## 5.4.21
- jumper 3.18.0
  - header removal feature
  - filter query params list 

## 5.4.20
- jumper 3.17.0
  - external idp 
- kong 2.8.3.12
  - rate-limiting-merged plugin 

## 5.4.19
- jumper 3.16.0
  - loadbalancing support
  - pass spectre info as event headers
- kong 2.8.3.11
  - rfc 6750 support within jwt-keycloak + acl plugins

## 5.4.18
- jumper 3.15.2
- improved responses from external IDPs in jumper in case of errors
- added logic to handle default-key in jc-oauth-config

## 5.4.17
- kong liveness probe to 1min
- configurable pre stop sleep with default 30s
- adjust jumper to 3.14.4

## 5.4.16
- pg ssl enabled by default for external
- jumper 3.14.3

## 5.4.15
- jumper 3.13.0
- add envs for redis configuration for fail over feature

## 5.4.14
- jumper 3.12.0
- pod antiAffinity preferred by default, optionally required
- labels update + added zone
- startup probe interval 1s

## 5.4.13
- jumper 3.11.0
- graceful shutdown with smaller timeouts for kong, jumper. issuer-service
- pod antiAffinity to required

## 5.4.12
- jumper 3.10.0
- issuer-service 1.11.1
- added probes for issuer-service
- increase default cpu limit for issuer-service

## 5.4.11
- ip-restriction support

## 5.4.10
- removed cequence auto configuration from configmap

## 5.4.9
- remove jsonWebKey, privateKey, publicKey references

## 5.4.8
- jumper 3.9.0
- pls note jumper 3.9.0 + is 1.10.0 needs new entries (certsJson, privateJson, publicJson) for runtime, old entries (jsonWebKey, privateKey, publicKey) should be removed with next release (including references)  

## 5.4.7
- remove checksum/secret-issuer-service
- remove generic checksum
- remove 2 unused params for is
- issuer service to 1.10.0
- mount issuer-keys
- added privateJson for jumper

## 5.4.6
- Kong 2.8.3.10
- remove unused parameters from prometheus job
- SERVER_maxHttpHeaderSize optional
- configurable maxUnavailable

## 5.4.5
- added proxy.ingress.secondHostname variable for extended ingress
- added proxy.ingress.secondTlsSecret variable for extended ingress

## 5.4.4
- added jumper environment variables for FPA Proxy Support
- Jumper 3.8.0
- Kong 2.8.3.9

## 5.4.3
- Kong 2.8.3.8: zipkin fix
- adjusted probes

## 5.4.2
 - added legacyIngress to support old hostnames

## 5.4.1
 - Fix: Global cequence plugins configuration

## 5.4.0
 - Introduced cequence compapatibility (no image provided)
 - Fixed failing Vault secret lookup for empty values
 - Fixed external database cert path
 - Jumper image 3.6.1
 - HPA kind autoscaling/v2

## 5.3.1
 - Kong 2.8.3.6: Admin API version info fix

## 5.3.0
 - added kong environment variables for worker consistency, state update frequency, database update frequency and propagation
 - jumper 3.6.0
 - jumper secret mount
 - kong 2.8.3.5
 - Added Argo CD secret redeploy trigger

## 5.2.0
- Allow ingressClassName setting
- Introduced tdi as platform
- Fixed config job authentication
- Fixed bootstrap job pod security context

## 5.1.1
- Fixed CaaS security context

## 5.1.0
- Fixed Jumper latency issue
- Jumper image 3.5.0
- Fixed Jumper header size too small (set to 16KB)

## 5.0.1
- Corrected migrations jobs db-check container security context
- Prometheus customer facing setting camelCase

## 5.0.0
- Removed double base 64 encryption
- Adjusted authorization process for jobs to -u user:password
- removed generation of htpasswd (needs to be stored manually now)

## 4.2.3
- global.adminApi.ingress.altHostname and global.proxy.ingress.altHostname settings added for second host name

## 4.2.2
- version tested on cass t21-cluster

## 4.2.1
- (invalid version. don't use this tag)

## 4.2.0
 - Platform dependent securityContexts
 - Platform dependent topologyKey
 - Introduced caas as platform
 - Set zone value fallback to platform 
 - Set environment value fallback to global metadata (from Sapling)

## 4.1.0
 - Default Jumper image version set to 3.4.3
 - Default Kong image version set to 2.8.3.4
 - tracing adjusted
 - zipkin config params: environment (not set for qa, physical env otherwise), zone (zone name), forceSample, headerType
 - Removed platform condition from ingress
 - Introduced caas as platform option
 - Caas platform specific topologyKey
 - Set default storageClassName by platform (caas: nfs-storage)

## 4.0.0
 - Reworked database configuration
 - Database integration reworked to sub-chart
 - Labels cleaned up
 - Corrected product names
 - Zipkin sample ratio set to 1
 - Unification of collectorUrl and global setting option
 - Prohibit changeme
 - PodSecurityContext for Stargate pod
 - StorageClasseName de-saplingized

## 3.7.0
 - securityContext divided into containerSecurityContext and podSecurityContext to satisfy CaaS cluster t21 policy

## 3.6.3
 - Added configurable Irix-Broker route to enable ZAM-login for external users
 - Added option to configure large_client_header_buffers in kong/nginx
 
## 3.6.1
 - Default Kong image version set to 2.8.3.3
 - "sec_event_code" renamed to "eventclassid"

## 3.6.0
 - Removed OpenShift and Enterprise remnants
 - Deactivated TLSv1.1
 - Updated cipher suites

## 3.5.0
 - Added request-size-limiting plugin setup

## 3.4.1
 - logging of soutce-ip changed to "$http_x_original_forwarded_for"

## 3.4.0
 - ENI-Kong image 2.8.3.2
 - Fixed Prometheus customer_facing always true 

## 3.3.0
 - ENI-Kong image 2.8.3.1
 - Altered Prometheus config for Plugin from Kong 3.1.1 (ENI 2.8.3.1)


## 3.2.0
 - ENI-Kong image 2.8.3.0

## 3.1.0
 - ENI-Kong image 2.8.1.2
 - Removed kong_admin and reworked plugins setup structure
 - Removed enterprise switches 

## 3.0.0
 - Use ENI flavoured original Prometheus plugin version 1.5.0
 - Use ENI flavoured original Zipkin plugin version 1.4.1
 - Switched to ENI-Kong image 2.8.1.1
 - Removed all plugins-setup e.g. init-container
 - Added jobs to remove old ENI flavoured plugins
 - Removed release names from containers

## 2.1.1
 - Set default log format to JSON

## 2.1.0
 - Added configurable initial delays
 - Added ingress tlsSecret
 - Security context fsGroup for postgres
 - ingressClassName for platform 'tdi'
 - Option logFormat with values [debug|default|json] modified in values.yaml

## 2.0.0
 - Pull images from new MTR
 - Using networking.k8s.io/v1 for ingress

## 1.25.1
 - avoid warnings by adding "sec_event" variables to admin port too

## 1.25.0
 - default kong-plugins image updated (containing security error codes)

## 1.24.6
 - Default size of metrics dictionary removed because of conflict with env variable

## 1.24.5
 - Fixed missing values.yaml settings for circuit breaker
 - Option logFormat with values [default|json|plain] added to values.yaml 
 - Alternative log formats pre-configured: log_proxy_json/log_admin_json and log_proxy_plain/log_admin_plain
 - Default size of metrics dictionary increased   

## 1.24.4
 - Fail on unset issuerService values for secret
 - Checksum for issuer service secret

## 1.24.3
 - Job hooks adapted

## 1.24.2
- Kong 2.8.1
- Kong Plugins 2.1.2
- Fixed missing openssl.rand issue

## 1.24.1
- Kong Plugins 2.1.1

## 1.24.0
- Kong 2.8.0
- Kong Plugins 2.1.0
- Simplified plugin container configuration

## 1.23.1
- Corrected circuit breaker image version

## 1.23.0
- added circuit breaker service (1.0.3)
- Issuer-service version 1.9.0
- Issuer-Service: Added jsonWebKey and publicKey secret
- jumper-sse to 2.3.4.3

## 1.22.2
 - status page (include in general already with 1.22.0), use sub product for developer-portal status page

## 1.22.1
 - Adapted pull secret handling

## 1.22.0
 - extended grace period to 80 seconds
 - added preStopHook with 65s sleep to jumper and legacy-jumper
 - Use dedicated jumper readiness and liveness probes

## 1.21.0
 - extended grace period to 65 seconds
 - jumper-legacy: 1.10.6.2-loglevel
 - jumper: 2.3.3
 - added jumper metrics endpoint to service and service monitor

## 1.20.2
 - legacy jumper exposes metrics
 - legacy jumper: 1.10.6.1-metrics
 - issuer-service: 1.8.0

## 1.20.1
 - jumper 2.2.5
 - legacy jumper 1.10.6.1
 - jumper name

## 1.20.0
  - Added legacy Jumper (1.10.5.3) container
  - Added env var KONG_NGINX_HTTP_LUA_SHARED_DICT
  - kong-plugins 2.0.1
  - Jumper 2.2.4.3
  - Port setting for Jumper

## 1.19.0
  - Update SSL Ciphers

## 1.18.0
  - Use jumper-sse 2.0.1

## 1.17.5
  - Added environment variables for jumper auto-event

## 1.17.4
  - Updated jumper to 1.10.4

## 1.17.3
  - Updated jumper to 1.10.3

## 1.17.2
  - Removed hook-succeeded from plugin jobs for debugging

## 1.17.1 
  - Updated jumper to 1.10.2

## 1.17.0
  - fixed lua template for caas
  - kong-plugins 2.0.0
  - Updated jumper to 1.10.0
  - readiness and liveness probe for jumper
  - readiness and liveness probe for kong

## 1.16.0-RC
  - Updated jumper to 1.9.7
 
## 1.15.0
  - fixed lua templates
  - kong-plugins 1.3.0

## 1.14.1
  - Updated jumper to 1.9.5
  - added environment variable tracingUrl for jumper to write traces

## 1.14.0
  - Allow pull policy changing
  - Pull policy IfNotPresent as default
  - PodAntiAffinity for node distribution
  - Added possibility for horizontal pod autoscaling

## 1.13.1
  - Updated jumper to 1.7.1

## 1.13.0
  - Admin API related security fixes
  - Trigger redeploy on secret-kong change
  - Updated jumper and issuer-service to 1.7.0

## 1.12.1
  - Issuer-service 1.5.0 with fixed certificate

## 1.12.0
  - Introduced issuer-service container

## 1.11.1
  - Set default migrations to none

## 1.11.0
  - Jumper 1.5.5

## 1.10.0
  - Added environment label for service monitor
  - Allow database schema configuration via KONG_PG_SCHEMA

## 1.9.0
  - Kong-plugins 1.2.0

## 1.8.2  
  - Corrected acl plugin 

## 1.8.1
  - Security context related fixes for CaaS compatibility 

## 1.8.0
  - Using eni-zipkin plugin instead of zipkin

## 1.7.1
  - Removed: Allow dedicated ignoreServices for our own Zipkin plugin

## 1.7.0
  - Auto job deletion for non-hook jobs
  - Allow dedicated ignoreServices for our own Zipkin plugin
  - ACL plugin overwrite fix

## 1.6.1
  - Fixed configuration overwrite

## 1.6.0
  - Added TargetLabels to ServiceMonitor 
  - Added separate jobs for bootstrapping and upgrade
  - Switch to Kong Community Edition 2.3.2
  - AdminApi ingress behaviour based on edition (CE or EE)
  - Updated Jumper to 1.3.5
  - CE: Admin API protection via proxy
  - Admin API backend and path depending on config and edition

## 1.5.0
  - Updated Jumper to 1.3.0
  - Added JUMPER_ISSUER_URL env var

## 1.4.3
  - Removed labels from Postgres

## 1.4.2
 - Log settings options
 - Added ConfigMap for pipeline meta data

## 1.4.1
 - Added ServiceMonitor which is now enabled by default. PodMonitor is now disabled by default

## 1.4.0

 - Allow TLSv1.2 and TLSv1.3 only, removed TLSv1 support
 - Make pod monitor selector configurable
 - Zipkin and Prometheus plugin configuration changes will now be properly applied

## 1.3.1

- Hotfix: Use "Recreate" strategy for database deployment

## 1.3.0

 - Made CPU, RAM and persistence resources configurable
 - Made the securityContext configurable
 - Adjusted resource request and limit defaults
 - Support for environments that prohibit writing to the root file system (like CaaS)
 - Edge TLS termination is now the default for the proxy

## 1.2.0

 - Allow setting of a Zipkin CA certificate
 - Allow setting of a external Postgres CA certificate
 - Global labels settings with a default fluentd label
 - Label deployments with chart version

## 1.1.0

 - DHEI-1712: Extended external database configuration
 - Removed kong prefix from servicePort to comply with requirements
 - Enterprise license stored in secret
 - Global ingress annotations setting

## 1.0.1

- Bugfix: Wrong secrets reference in non-rbac case for plugin-enabling jobs
- Added job to enable Prometheus plugin on global default workspace

## 1.0.0

- DHEI-1430: Hostname setting for every ingress/route
- DHEI-1430: Annotations overwrite for ingress/routes
- DHEI-1136: Added option to enable and configure Zipkin-Plugin
- DHEI-967: Added option to configure mTLS Proxy to present a server cert
- DHEI-1135: Added option to enable a metrics service that can be found scraped by Prometheus
