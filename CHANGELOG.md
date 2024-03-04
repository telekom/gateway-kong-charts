<!--
SPDX-FileCopyrightText: 2023 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

**Table of contents**

This document show changes done to the chart.
Please also seek advice from the README regarding updates.


[[_TOC_]]
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

