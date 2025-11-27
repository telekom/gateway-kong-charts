<!--
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Upgrade

This document provides guidance for upgrading between versions of the Gateway Helm chart.

## From 8.x.x to 9.x.x

Version 9.0.0 introduces several breaking changes that modernize the chart structure and align with Kubernetes best practices. Review all changes carefully before upgrading.

### Chart Distribution via OCI Registry

The chart is now published to GitHub Container Registry (GHCR) and can be installed directly without cloning the repository:

```bash
helm install my-gateway oci://ghcr.io/telekom/o28m-charts/stargate --version 9.0.0 -f my-values.yaml
```

This provides easier installation and version management. The traditional Git-based installation method remains supported.

### Image Configuration Structure (BREAKING)

The image configuration structure has been completely redesigned with cascading defaults.

**Old structure:**
```yaml
global:
  image:
    repository: mtr.devops.telekom.de
    organization: tardis-common
    force: false  # Replace repository/organization even in custom image strings

# Component-level (structured form)
image:
  repository: mtr.devops.telekom.de
  organization: tardis-internal/gateway
  name: kong
  tag: "1.0.1"

# Or flattened string form
image: mtr.devops.telekom.de/tardis-internal/gateway/kong:1.0.1
```

Images were constructed as: `{repository}/{organization}/{name}:{tag}`

**New structure:**
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

Images are now constructed as: `{registry}/{namespace}/{repository}:{tag}`

**Key changes:**
- `repository` → `registry` (the base registry URL)
- `organization` → `namespace` (the namespace/path within the registry)
- `name` → `repository` (the image repository name)
- `force` flag removed (simplified mechanism)
- Flattened string format no longer supported

**Required changes:**
- Update all custom image configurations to the new structure
- Component images now use the `gateway-*` naming convention (e.g., `gateway-kong`, `gateway-jumper`)
- Default namespace changed to `eu_it_co_development/o28m`
- The same pattern applies to PostgreSQL and all job images

**Migration example:**
```yaml
# Before (structured form)
image:
  repository: my-registry.com
  organization: my-org
  name: custom-kong
  tag: "2.0.0"

# Or before (flattened string form)
image: my-registry.com/my-org/custom-kong:2.0.0

# After
image:
  registry: my-registry.com
  namespace: my-org
  repository: custom-kong
  tag: "2.0.0"

# Or use global defaults with component override
global:
  image:
    registry: my-registry.com
    namespace: my-org
image:
  repository: custom-kong
  tag: "2.0.0"
```

### Platform Configuration Removal (BREAKING)

The platform-specific configuration mechanism has been removed. Platform-specific values are now integrated as explicit defaults in `values.yaml`.

**Removed:**
- `global.platform` configuration option
- `platforms/` folder (aws.yaml, caas.yaml, tdi.yaml)
- `platformSpecificValue` template helper

**What changed:**
- Hardened security contexts (previously in platforms/caas.yaml) are now default in `values.yaml`
- Storage class now uses cluster default instead of hardcoded `gp2`
- Ingress class now uses cluster default with cascading configuration
- No more platform-specific overlays

**Required changes:**
- Remove `global.platform: caas` (or similar) from your values
- If you relied on platform-specific values, you must now set them explicitly in your values files
- Review the new defaults in `values.yaml` and adjust if needed

**Migration example:**
```yaml
# Before
global:
  platform: caas  # This no longer works

# After - Set values explicitly
postgresql:
  persistence:
    storageClassName: ""  # Uses cluster default
  securityContext:
    runAsNonRoot: true
    runAsUser: 999
    # ... other hardened defaults now in values.yaml
```

### Label Standardization (BREAKING)

All resource labels have been refactored to follow Kubernetes recommended labels and introduce classification labels for better resource identification.

**Changes:**
- Implemented Kubernetes recommended labels (`app.kubernetes.io/*`)
- Automatic `tardis.telekom.de/*` labels **removed** (must be set manually via `global.labels`)
- Added `ei.telekom.de/zone` and `ei.telekom.de/environment` classification labels
- `global.metadata.environment` deprecated in favor of `global.environment`
- Prometheus metric labels changed from `tardis_telekom_de_*` to `ei_telekom_de_*`
- Argo Rollouts analysis arguments changed: now uses three separate arguments (`zone`, `environment`, `instance`) instead of single `namespace` argument

**Required changes:**
```yaml
# Before
global:
  metadata:
    environment: production

# After
global:
  environment: production
  zone: aws-eu-central-1  # New required field

# If you need tardis.telekom.de/* labels, set them manually:
global:
  labels:
    "tardis.telekom.de/team": "my-team"
    "tardis.telekom.de/product": "gateway"
```

**Impact on monitoring:**
- To maintain existing monitoring functionality with `tardis_telekom_de_*` labels, set the `tardis.telekom.de/*` labels manually in `global.labels`
- ServiceMonitor automatically transfers all `global.labels` to metrics
- Alternatively, update Prometheus queries, dashboards, and alerts to use the new `ei_telekom_de_zone` and `ei_telekom_de_environment` labels

**Impact on KEDA and Argo Rollouts:**
- KEDA queries now use `ei_telekom_de_environment` and `ei_telekom_de_zone`
- Argo Rollouts analysis templates use new `environment` argument instead of `namespace`
- Custom analysis templates will require updates

### PostgreSQL Subchart Integration

PostgreSQL is no longer a Helm subchart dependency and has been integrated directly into the main chart templates. The values structure remains identical under the `postgresql:` key — no changes required.

### Pipeline Metadata Removal

ENI-specific pipeline deployment metadata has been removed as it is no longer used.

**Removed:**
- Pipeline metadata annotations
- `configmap-pipeline-metadata.yaml` template
- Related values configuration

### Storage and Ingress Class Defaults

**Storage Class:**
- Changed from hardcoded `gp2` (AWS-specific) to cluster default (`storageClassName: ""`)
- Override per component as needed

**Ingress Class:**
- Changed from hardcoded `nginx` to cluster default
- Supports cascading: component `className` → `global.ingress.ingressClassName` → cluster default

```yaml
# Set global default for all ingresses
global:
  ingress:
    ingressClassName: nginx

# Or override per component
proxy:
  ingress:
    className: traefik
```

## From 7.x.x to 8.x.x

### HPA Configuration

The HPA configuration has been renamed from `autoscaling` to `hpaAutoscaling` in `values.yaml`. You can now choose between `hpaAutoscaling` and `kedaAutoscaling`. See the [Autoscaling](README.md#autoscaling) section for details.

### Migration to gateway-kong-image 1.1.0

This release upgrades the default image to version 1.1.0 (based on Kong 3.9.1) and requires an important migration step during the Helm upgrade process.

#### Required Migration Step

Set the `migrations: upgrade` Helm value to trigger necessary Kong migration jobs. After a successful upgrade, remove this value. The migration process is idempotent — multiple upgrades with this property will not cause issues.

⚠️ **Warning:** This upgrade runs Kong migration scripts that modify the database. Create a backup before upgrading. Disable the Kong Admin API during backup and upgrade. Once complete and the gateway is running, re-enable the Admin API — the control plane will then synchronize the Kong configuration.

#### Sample Upgrade Process

Example upgrade process (assuming you're in the Helm chart root directory with an existing release):

```bash
helm upgrade <releasename> . -f <customvaluefilereference> --set migrations=upgrade
```

#### Rollback Considerations

While initial testing suggests a database upgraded to gateway-kong-image 1.1.0 (Kong 3.9.1) works with Helm chart version 7.x.x, compatibility cannot be guaranteed for all Kong features. In case of rollback:

- Be prepared to restore the previous database state
- Rolling back to an older database state will likely cause synchronization issues between gateway-kong and the control plane
- Trigger a full reconfiguration to synchronize with control plane changes


## From 6.x.x to 7.x.x

### Health Probe Configuration

If you have custom Helm values for health probes, review the new configuration method. Specific probe variables have been removed in favor of Kubernetes defaults.

Deployments now render YAML values as defined in `values.yaml`. Example default probe configuration:

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

### Certificate Changes

The following configuration is now obsolete. The corresponding Secret is no longer rendered.

```yaml
issuerService:
  certsJson: changeme
  publicJson: changeme
  privateJson: changeme
```

Two options are now available for private/public key and certificate rotation:

1. Use `keyRotation.enabled=true` to deploy manifests for automatic rotation. This requires running cert-manager and our [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process) operator.
2. Provide your own secrets via `jumper.existingJwkSecretName` and `issuerService.existingJwkSecretName`. Secrets must be identical and conform to the format described in [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process).

Refer to [cert-manager](https://cert-manager.io/docs/) and [gateway-rotator](https://github.com/telekom/gateway-rotator?tab=readme-ov-file#key-rotation-process) documentation for more information.


## From 5.x.x to 6.x.x

Ingress configuration has been streamlined to support multiple hostnames and align with Helm chart best practices.

**Before:**

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

**After:**

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

This enables flexible ingress configuration with multiple hosts and different TLS secrets per host. Note: `proxy.tls.enabled` and `adminApi.tls.enabled` properties remain unchanged.


## From 4.x.x to 5.x.x

Starting from version 5, htpasswd must be generated and set manually. This is required because Vault does not support double-encoded base64 secrets. See the [htpasswd](README.md#htpasswd) section.


## From 2.x.x and Lower to 4.x.x

Direct migration from 2.x.x to 4.x.x is not supported. First upgrade from 2.x.x to 3.x.x as described above, then upgrade from 3.x.x to 4.x.x without any migration configuration.


## From 2.x.x and Lower to 3.x.x

ENI plugin integration has changed. Plugin names were updated and ENI-prefixed plugins were removed from the image. The Kong database configuration must be updated accordingly.

Activate the jobs migration to delete old ENI plugins and enable the new ones:

```yaml
migrations: jobs
```


## From 1.7.x and Lower to 1.8.x and Up

The bundled Zipkin plugin has been replaced by ENI-Zipkin plugin. Behavior and configuration differ slightly.

Strongly recommended: Remove the existing Zipkin plugin before upgrading via a DELETE call on the Admin API (token required).

**Look up all plugins and find the Zipkin plugin ID:**

```sh
via GET on https://admin-api-url.me/plugins
```

**Delete the existing plugin:**

```sh
via DELETE on https://admin-api-url.me/plugins/<zipkinPluginId>
```


## From 1.5.x and Lower to 1.6.x

Kong CE introduces dedicated Admin API handling to protect the Admin API, requiring changes to the Admin API ingress.

Changes are reflected in `ingress-admin.yml` only, not in `route-admin.yml`. Kong CE works correctly, but deploying the Admin-API Route provides unsecured access to the Admin API.


## To 1.24.0 and Up

This version introduces Kong 2.8.1 and requires running migrations. It also requires adapting to changed `securityContext` settings for `plugins` in `values.yaml`.


## To 1.23.0 and Up

Version 1.23.0 introduces a new issuer service version. If using the issuer service, set values for the new secret `secret-issuer-service.yml`. Replace `jsonWebKey: changeme` and `publicKey: changeme`.
