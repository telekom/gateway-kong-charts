<!--
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Upgrade

This document provides guidance for upgrading between versions of the Gateway Helm chart.

## From 7.x.x To Version 8.x.x

### HPA configuration

The HPA configuration has been renamed from `autoscaling` to `hpaAutoscaling` in `values.yaml`.
You can now select between using hpaAutoscaling and kedaAutoscaling. More information about this is provided in [Autoscaling](#autoscaling).

### Migration to gateway-kong-image 1.1.0

This release upgrades the default image to version 1.1.0, which is based on Kong 3.9.1. This upgrade requires an important step during the Helm upgrade process.

#### Required Migration Step

For a successful upgrade, you must set the `migrations: upgrade` Helm value to trigger the necessary Kong migration jobs. After a successful upgrade, this value can be safely removed. The migration process is idempotent, so multiple Helm upgrades with this property will not cause issues.

⚠️ Warning: This upgrade will run Kong migration scripts that modify the database. Please create a consistent backup before upgrading. The Kong Admin API must be disabled during both the backup creation and the upgrade process. Once the upgrade is complete and the gateway is running correctly, the Admin API can be re-enabled. The control plane will then synchronize the Kong configuration to the desired state.

#### Sample Upgrade Process

A simple upgrade process would look like the following (assuming you're in the root directory of the Helm chart with an existing release):

```bash
helm upgrade <releasename> . -f <customvaluefilereference> --set migrations=upgrade
```

#### Rollback Considerations

While initial testing suggests that a database upgraded to gateway-kong-image 1.1.0 (Kong 3.9.1) can still be used with Helm chart version 7.x.x, this compatibility cannot be guaranteed for all Kong features. In case of a rollback:

Be prepared to restore the previous database state
Be aware that rolling back to an older database state will likely cause synchronization issues between gateway-kong and the control plane
If rollback is necessary, you will need to trigger a full reconfiguration to synchronize with changes in the control plane


## From 6.x.x To Version 7.x.x

### Health probe configurations

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

### Certificate Changes

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


## From 5.x.x to Version 6.x.x

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


## From 4.x.x to Version 5.x.x

Starting from version 5 and above the htpasswd needs to be generated and set manually. \
This is necessary as double encoded base64 secrets are not supported by Vault. \
See chapter [htpasswd](#htpasswd).


## From 2.x.x and lower to 4.x.x

The migration from 2.x.x to 4.x.x is not possible. Please upgrade first from 2.x.x to 3.x.x as described above and afterwards without any migrations configuration from 3.x.x to 4.x.x


## From 2.x.x and lower to 3.x.x

We changed the integration of the ENI-plugins. Therefore names of the plugins changed and and eni-prefixed plugins have been removed from the image. Therefore the configuration of Kong itself, precisely the database, needs to be updated.
You can do this by activating the jobs migration. This will delete the "old" ENI-plugins to allow the configuration of the new ones.

```yaml
migrations: jobs
```


## From 1.7.x and lower to 1.8.x and up

The bundled Zipkin-plugin has been replaced by the ENI-Zipkin pluging. Behaviour and configuration differ slightly to the used one.
To avoid complications, we strongly recommend removing the existing Zipkin-Plugin before upgrading. This can be done via a DELETE call on the Admin-API (Token required).

Lookup all plugins and find the Zipkin-Plugin-ID:

```sh
via GET on https://admin-api-url.me/plugins
```

Deleting the existing plugin:

```sh
via DELETE on https://admin-api-url.me/plugins/<zipkinPluginId>
```


## From 1.5.x and lower to 1.6.x

With introduction of Kong CE, a dedicated Admin-API handling has been introduced to proted the Admin-API. This required changes to the ingress of the Admin-API.
Those changes are only reflected in the `ingress-admin.yml` and not in the `route-admin.yml`. Using Kong CE will work, but deploying the Admin-API-Route will provide unsecured access to the Admin-API.


## To 1.24.0 and up

This version introduces Kong 2.8.1 and requires migrations to be run.\
It also requires to adapt to the changed `securityContext` settings of the `plugins` in the `values.yaml`.


## To 1.23.0 and up

Version 1.23.0 introduces a new issuer service version. If in use, this requires to set values for the new secret `secret-issuer-service.yml`. \
Replace `jsonWebKey: changeme` and `publicKey: changeme`.
