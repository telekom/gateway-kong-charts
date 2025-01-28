{{- define "kong.labels" -}}
app: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: kong
{{ include "kong.selector" . }}
app.kubernetes.io/component: api-gateway
app.kubernetes.io/part-of: tardis-runtime
{{ .Values.global.labels | toYaml }}
{{- end -}}

{{- define "kong.selector" -}}
app.kubernetes.io/instance: {{ .Release.Name }}-kong
{{- end -}}

{{- define "kong.image" -}}
{{- $imageName := "eni-kong" -}}
{{- $imageTag := "2.8.3.12" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-internal/io" -}}
{{- if .Values.image -}}
  {{- if not (kindIs "string" .Values.image) -}}
    {{ $imageRepository = .Values.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.image.name | default $imageName -}}
    {{ $imageTag = .Values.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-internal/io" .Values.global.image.organization -}}
    {{- else -}}
      {{- .Values.image -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "job.image" -}}
{{- $imageName := "tif-base-image" -}}
{{- $imageTag := "1.0.0" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-common" -}}
{{- if and .Values.job .Values.job.image -}}
  {{- if not (kindIs "string" .Values.job.image) -}}
    {{ $imageRepository = .Values.job.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.job.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.job.image.name | default $imageName -}}
    {{ $imageTag = .Values.job.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.job.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-common" .Values.global.image.organization -}}
    {{- else -}}
      {{- .Values.job.image -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "kong.jumper.image" -}}
{{- $imageName := "jumper-sse" -}}
{{- $imageTag := "3.18.0" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-internal/hyperion" -}}
{{- if .Values.jumper.image -}}
  {{- if not (kindIs "string" .Values.jumper.image) -}}
    {{ $imageRepository = .Values.jumper.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.jumper.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.jumper.image.name | default $imageName -}}
    {{ $imageTag = .Values.jumper.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.jumper.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-internal/hyperion" .Values.global.image.organization -}}
    {{- else -}}
      {{- .Values.jumper.image -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "kong.legacyJumper.image" -}}
{{- $imageName := "jumper" -}}
{{- $imageTag := "1.10.6.3" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-internal/hyperion" -}}
{{- if .Values.legacyJumper.image -}}
  {{- if not (kindIs "string" .Values.legacyJumper.image) -}}
    {{ $imageRepository = .Values.legacyJumper.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.legacyJumper.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.legacyJumper.image.name | default $imageName -}}
    {{ $imageTag = .Values.legacyJumper.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.legacyJumper.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-internal/hyperion" .Values.global.image.organization -}}
    {{- else -}}
    {{- end -}}
    {{- .Values.legacyJumper.image -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "kong.issuerService.image" -}}
{{- $imageName := "issuer-service" -}}
{{- $imageTag := "1.11.1" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-internal/hyperion" -}}
{{- if .Values.issuerService.image -}}
  {{- if not (kindIs "string" .Values.issuerService.image) -}}
    {{ $imageRepository = .Values.issuerService.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.issuerService.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.issuerService.image.name | default $imageName -}}
    {{ $imageTag = .Values.issuerService.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.issuerService.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-internal/hyperion" .Values.global.image.organization -}}
    {{- else -}}
    {{- end -}}
    {{- .Values.issuerService.image -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "kong.circuitbreaker.image" -}}
{{- $imageName := "gateway-circuitbreaker" -}}
{{- $imageTag := "2.1.0" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-internal/hyperion" -}}
{{- if .Values.circuitbreaker.image -}}
  {{- if not (kindIs "string" .Values.circuitbreaker.image) -}}
    {{ $imageRepository = .Values.circuitbreaker.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.circuitbreaker.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.circuitbreaker.image.name | default $imageName -}}
    {{ $imageTag = .Values.circuitbreaker.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.circuitbreaker.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-internal/hyperion" .Values.global.image.organization -}}
    {{- else -}}
    {{- end -}}
    {{- .Values.circuitbreaker.image -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "kong.issuerService.env" }}
- name: JUMPER_ISSUER_URL
  value: {{ .Values.jumper.issuerUrl }}
{{- end -}}

{{- define "kong.circuitbreaker.env" }}
- name: KONG_AUTH
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}
      key: gatewayAdminApiKey
- name: KONG_URL
  value: {{ include "kong.adminApi.localhost" $ }}
- name: INTERVAL
  value: {{ .Values.circuitbreaker.interval | default "60s" | quote }}
- name: COUNT
  value: {{ .Values.circuitbreaker.count | default "4" | quote}}
{{- end -}}

{{- define "kong.bundledTrustedCaCertificates" }}
{{ include "kong.luaSslTrustedCertificates" $ }}
{{ .Values.trustedCaCertificates }}
{{ end -}}

{{- define "kong.annotations" -}}
ops.eni.telekom.de/pipeline-meta-ref: {{ .Release.Name }}-pipeline-metadata
{{- if eq (toString .Values.global.metadata.pipeline.forceRedeploy) "true" }}
ops.eni.telekom.de/pipeline-force-redeploy: '{{ now | date "2006-01-02T15:04:05Z07:00" }}'
{{- end -}}
{{- end -}}

{{- define "kong.checksums" -}}
checksum/secret-kong: {{ include (print $.Template.BasePath "/secret-kong.yml") . | sha256sum }}
{{ include "argo.checksum" (list $ . ".Values.adminApi.htpasswd") }}
{{ include "argo.checksum" (list $ . ".Values.adminApi.gatewayAdminApiKey") }}
{{ include "argo.checksum" (list $ . ".Values.global.database.password") }}
{{- if eq .Values.sslVerify true }}
checksum/trusted-ca-certificates: {{ (include "kong.bundledTrustedCaCertificates" $ | default "# Set trustedCaCertificates in values.yaml") | sha256sum }}
{{ include "argo.checksum" (list $ . ".Values.trustedCaCertificates") }}
{{ if  .Values.plugins.zipkin.luaSslTrustedCertificate }}
{{ include "argo.checksum" (list $ . ".Values.plugins.zipkin.luaSslTrustedCertificate") }}
{{- end -}}
{{- end -}}
{{- range .Values.templateChangeTriggers }}
checksum/{{ . }}: {{ include (print $.Template.BasePath "/" . ) $ | sha256sum }}
{{- end -}}
{{- end -}}

{{- define "kong.configuration" -}}
{{- if eq .Values.adminApi.enabled true -}}
true
{{- else }}
false
{{- end -}}
{{- end -}}

{{- define "kong.isZipkinEnabled" -}}
{{- if (eq .Values.plugins.zipkin.enabled true) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "kong.isMigrationsJob" -}}
{{- if .Values.migrations -}}
{{- if eq .Values.migrations "jobs" -}}
true
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "kong.isMigrationsBootstrap" -}}
{{- if .Values.migrations -}}
{{- if eq .Values.migrations "bootstrap" -}}
true
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "kong.isMigrationsUpgrade" -}}
{{- if .Values.migrations -}}
{{- if eq .Values.migrations "upgrade" -}}
true
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "kong.configuration.volumes" }}
- name: kong-configuration
  configMap:
    name: {{ .Release.Name }}-configuration
    defaultMode: 0555
{{- end -}}

{{- define "kong.configuration.volumeMounts" }}
- name: kong-configuration
  mountPath: /tmp
{{- end -}}

{{- define "kong.migrations.volumes" }}
- name: local-luarocks
  emptyDir: {}
- name: kong-migrations-prefix-dir
  emptyDir: {}
- name: kong-migrations-tmp
  emptyDir: {}
{{- if .Values.externalDatabase.sslVerify }}
- name: lua-ssl-trusted-certificates
  secret:
    secretName: {{ .Release.Name }}-trusted-ca-certificates
    items:
      - key: lua-ssl-trusted-certificates.pem
        path: 'init/lua-ssl-trusted-certificates.pem'
{{- end -}}
{{- end -}}

{{- define "kong.migrations.volumeMounts" }}
- name: local-luarocks
  mountPath: /home/kong/.luarocks
- name: kong-migrations-prefix-dir
  mountPath: /kong
- name: kong-migrations-tmp
  mountPath: /tmp
{{- if .Values.externalDatabase.sslVerify }}
- name: lua-ssl-trusted-certificates
  mountPath: /opt/kong/tls
{{- end -}}
{{- end -}}

{{- define "kong.volumes" }}
- name: local-luarocks
  emptyDir: {}
- name: kong-prefix-dir
  emptyDir: {}
- name: kong-tmp
  emptyDir: {}
- name: nginx-kong-template
  configMap:
    name: {{ .Release.Name }}-nginx-kong-template
- name: htpasswd
  secret:
    secretName: {{ .Release.Name }}
- name: nginx-servers
  configMap:
    name: {{ .Release.Name }}-nginx-servers
{{- if or (eq .Values.sslVerify true) .Values.plugins.zipkin.luaSslTrustedCertificate .Values.externalDatabase.sslVerify }}
- name: trusted-ca-certificates
  secret:
    secretName: {{ .Release.Name }}-trusted-ca-certificates
{{- end -}}
{{- if .Values.defaultTlsSecret }}            
- name: server-certificate
  secret:
    secretName: {{ .Values.defaultTlsSecret }}
{{- end -}}
{{- end -}}

{{- define "kong.volumeMounts" }}
- name: local-luarocks
  mountPath: /home/kong/.luarocks
- name: kong-prefix-dir
  mountPath: /kong
- name: kong-tmp
  mountPath: /tmp
- name: nginx-kong-template
  mountPath: /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua
  subPath: nginx_kong.lua
- name: htpasswd
  mountPath: /opt/kong/.htpasswd
  subPath: .htpasswd
- name: nginx-servers
  mountPath: /opt/kong/nginx
{{- if or (eq .Values.sslVerify true) .Values.plugins.zipkin.luaSslTrustedCertificate .Values.externalDatabase.sslVerify }}
- name: trusted-ca-certificates
  mountPath: /opt/kong/tls
{{- end -}}
{{- if .Values.defaultTlsSecret }}            
- name: server-certificate
  mountPath: /opt/kong/default-https
{{- end -}}
{{- end -}}

{{- define "kong.jumper.volumes" }}
- name: kong-jumper-tmp
  emptyDir: {}
- name: jumper-keys
  secret:
    secretName: {{ .Release.Name }}-issuer-service
    items:
      - key: privateJson
        path: private.json
    defaultMode: 420
    optional: true
{{- end -}}

{{- define "kong.jumper.volumeMounts" }}
- name: kong-jumper-tmp
  mountPath: /tmp
- name: jumper-keys
  mountPath: /usr/share/keypair
  readOnly: true
{{- end -}}

{{- define "kong.issuerService.volumes" }}
- name: kong-issuer-tmp
  emptyDir: {}
- name: issuer-keys
  secret:
    secretName: {{ .Release.Name }}-issuer-service
    items:
      - key: publicJson
        path: public.json
      - key: certsJson
        path: certs.json
    defaultMode: 420
    optional: true
{{- end -}}

{{- define "kong.issuerService.volumeMounts" }}
- name: kong-issuer-tmp
  mountPath: /tmp
- name: issuer-keys
  mountPath: /usr/share/keypair
  readOnly: true
{{- end -}}

{{- define "kong.circuitbreaker.volumes" }}
- name: kong-circuitbreaker-tmp
  emptyDir: {}
{{- end -}}

{{- define "kong.circuitbreaker.volumeMounts" }}
- name: kong-circuitbreaker-tmp
  mountPath: /tmp
{{- end -}}

{{- define "kong.nginx.directives" }}
- name: KONG_NGINX_WORKER_PROCESSES
  value: '{{ .Values.nginxWorkerProcesses | default "4" }}'
- name: KONG_NGINX_HTTP_INCLUDE
  value: '/opt/kong/nginx/servers.conf'
- name: KONG_NGINX_HTTP_LUA_SHARED_DICT
  value: '{{ .Values.nginxHttpLuaSharedDict | default "prometheus_metrics 15m" }}'
{{- if .Values.nginxLargeClientBuffers }}
- name: KONG_NGINX_PROXY_LARGE_CLIENT_HEADER_BUFFERS
  value: '{{ .Values.nginxLargeClientBuffers | default "4 8k" }}'
{{- end -}}
{{- if .Values.defaultTlsSecret }}
- name: KONG_SSL_CERT
  value: /opt/kong/default-https/tls.crt
- name: KONG_SSL_CERT_KEY
  value: /opt/kong/default-https/tls.key
{{- end }}
{{- if eq .Values.sslVerify true }}
- name: KONG_NGINX_PROXY_PROXY_SSL_TRUSTED_CERTIFICATE
  value: '/opt/kong/tls/trusted-ca-certificates.pem'
- name: KONG_NGINX_PROXY_PROXY_SSL_VERIFY
  value: 'on'
- name: KONG_NGINX_PROXY_PROXY_SSL_VERIFY_DEPTH
  value: '{{ .Values.sslVerifyDepth | default '1' }}'
{{- end -}}
{{- if eq .Values.disableUpstreamCache true }}
# See: : https://github.com/openresty/lua-resty-core/pull/276/files#diff-c6d3d61f52132e153660e7832e95b88aR340-R349
- name: KONG_NGINX_HTTP_UPSTREAM_KEEPALIVE
  value: 'NONE'
{{- end -}}
{{- end -}}

{{- define "kong.luaSslTrustedCertificates" }}
{{- if .Values.plugins.zipkin.luaSslTrustedCertificate -}}
{{ .Values.plugins.zipkin.luaSslTrustedCertificate }}
{{- end -}}
{{- if .Values.externalDatabase.luaSslTrustedCertificate -}}
{{ .Values.externalDatabase.luaSslTrustedCertificate }}
{{- end -}}
{{ end -}}

{{- define "kong.env.prefix" }}
- name: KONG_PREFIX
  value: /kong
{{- end -}}

{{- define "kong.migrations.checkdatabase.env" }}
- name: PGHOST
  value: {{ include "database.host" $ }}
- name: PGDATABASE
  value: {{ .Values.global.database.database }}
- name: PGUSER
  value: {{ .Values.global.database.username }}
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}
      key: databasePassword
{{- end -}}

{{- define "kong.migrations.env" }}
- name: KONG_DATABASE
  value: postgres
{{- template "kong.env.prefix" . }}
- name: KONG_PG_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}
      key: databasePassword
- name: KONG_PG_PORT
  value: '{{ .Values.global.database.port }}'
- name: KONG_PG_HOST
  value: '{{ include "database.host" $ }}'
- name: KONG_PG_USER
  value: '{{ .Values.global.database.username }}'
- name: KONG_PG_DATABASE
  value: '{{ .Values.global.database.database }}'
- name: KONG_PG_SCHEMA
  value: '{{ .Values.global.database.schema }}'
{{- if eq .Values.global.database.location "external" }}
{{- if ne .Values.externalDatabase.ssl false }}
- name: KONG_PG_SSL
  value: 'on'
{{- if .Values.externalDatabase.sslVerify }}
- name: KONG_PG_SSL_VERIFY
  value: 'on'
- name: KONG_LUA_SSL_TRUSTED_CERTIFICATE
  value: '/opt/kong/tls/init/lua-ssl-trusted-certificates.pem'
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kong.env" }}
- name: KONG_MEM_CACHE_SIZE
  value: '{{ .Values.memCacheSize | default "128m" }}'
- name: KONG_WORKER_CONSISTENCY
  value: '{{ .Values.workerConsistency | default "eventual" }}'
- name: KONG_WORKER_STATE_UPDATE_FREQUENCY
  value: '{{ .Values.workerStateUpdateFrequency | default "10" }}'
- name: KONG_DB_UPDATE_FREQUENCY
  value: '{{ .Values.dbUpdateFrequency | default "10" }}'
- name: KONG_DB_UPDATE_PROPAGATION
  value: '{{ .Values.dbUpdatePropagation | default "0" }}'
- name: KONG_ANONYMOUS_REPORTS
  value: 'false'
- name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE
  value: '{{ .Values.httpClientBodyBufferSize | default "4m" }}'
{{- if .Values.trustedIps }}
- name: KONG_TRUSTED_IPS
  value: '{{ .Values.trustedIps }}'
- name: KONG_REAL_IP_HEADER
  value: '{{ .Values.realIpHeader | default "x-original-forwarded-for" }}'
- name: KONG_REAL_IP_RECURSIVE
  value: '{{ .Values.realIpRecursive | default "OFF" }}'
{{- end }}
{{- template "kong.env.prefix" . }}
- name: KONG_DATABASE
  value: postgres
- name: KONG_PG_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}
      key: databasePassword
- name: KONG_PG_PORT
  value: '{{ .Values.global.database.port | default 5432 }}'
- name: KONG_PG_HOST
  value: '{{ include "database.host" $ }}'
- name: KONG_PG_USER
  value: '{{ .Values.global.database.username }}'
- name: KONG_PG_DATABASE
  value: '{{ .Values.global.database.database }}'
- name: KONG_PG_SCHEMA
  value: '{{ .Values.global.database.schema }}'
- name: KONG_PROXY_ACCESS_LOG
  value: {{ .Values.proxy.accessLog | default "/dev/stdout" | quote }}
- name: KONG_PROXY_ERROR_LOG
  value: {{ .Values.proxy.errorLog | default "/dev/stderr" | quote }}
{{- if eq .Values.global.database.location "external" }}
{{- if ne .Values.externalDatabase.ssl false }}
- name: KONG_PG_SSL
  value: 'on'
{{- if .Values.externalDatabase.sslVerify }}
- name: KONG_PG_SSL_VERIFY
  value: 'on'
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.ssl.cipherSuite }}
- name: KONG_SSL_CIPHER_SUITE
  value: {{ .Values.ssl.cipherSuite | quote }}
{{- end }}
{{- if .Values.ssl.ciphers }}
- name: KONG_SSL_CIPHERS
  value: {{ .Values.ssl.ciphers | quote }}
{{- end }}
- name: KONG_SSL_PROTOCOLS
  value: {{ .Values.ssl.protocols | quote }}
- name: KONG_LUA_SSL_PROTOCOLS
  value: {{ .Values.ssl.protocols | quote }}
- name: KONG_PROXY_LISTEN
{{- if .Values.proxy.tls.enabled }}
  value: '0.0.0.0:8443 ssl http2'
{{- else }}
  value: '0.0.0.0:8000'
{{- end -}}
{{- if .Values.adminApi.enabled }}
- name: KONG_ADMIN_LISTEN
{{- if .Values.adminApi.tls.enabled }}
  value: '0.0.0.0:8444 ssl'
{{- else }}
  value: '0.0.0.0:8001'
{{- end }}
- name: KONG_STATUS_LISTEN
  value: '0.0.0.0:8100'
- name: KONG_ADMIN_ACCESS_LOG
  value: {{ .Values.adminApi.accessLog | default "/dev/stdout" | quote }}
- name: KONG_ADMIN_ERROR_LOG
  value: {{ .Values.adminApi.errorLog | default "/dev/stderr" | quote }}
{{- end }}
{{- include "kong.kongLuaSslTrustedCertificatePath" . -}}
{{- end }}

{{- define "kong.kongLuaSslTrustedCertificatePath" -}}
{{ $path := "" }}
{{- if or .Values.plugins.zipkin.luaSslTrustedCertificate (and .Values.externalDatabase.ssl .Values.externalDatabase.sslVerify) }}
{{ $path = printf "%s,%s" $path "/opt/kong/tls/lua-ssl-trusted-certificates.pem" }}
{{- end }}
{{- if eq .Values.plugins.cequence.enabled true }}
{{ $path = printf "%s,%s" $path "system" }}
{{- end }}
{{- if not (empty $path) -}}
- name: KONG_LUA_SSL_TRUSTED_CERTIFICATE
  value: {{ $path | trimAll "," | quote }}
{{- end -}}
{{- end -}}

{{- define "kong.jumper.collectorUrl" -}}
{{ $url := .Values.jumper.tracingUrl | default .Values.global.tracing.collectorUrl -}}
{{ trimSuffix "/api/v2/spans" $url -}}
{{- end -}}

{{- define "kong.jumper.env" }}
- name: JUMPER_ISSUER_URL
  value: {{ .Values.jumper.issuerUrl }}
- name: JUMPER_ZONE_NAME
  value: {{ .Values.global.zone }}
- name: TRACING_URL
  value: {{ include "kong.jumper.collectorUrl" . }}
- name: STARGATE_URL
  value: {{ .Values.jumper.stargateUrl }}
{{- if .Values.jumper.zoneHealth.enabled }}
- name: ZONE_HEALTH_DATABASE_CONNECTTIMEOUT
  value: {{ .Values.jumper.zoneHealth.databaseConnectionTimeout | quote }}
- name: ZONE_HEALTH_DATABASE_TIMEOUT
  value: {{ .Values.jumper.zoneHealth.databaseTimeout | quote }}
- name: ZONE_HEALTH_DATABASE_HOST
  value: {{ .Values.jumper.zoneHealth.databaseHost }}
- name: ZONE_HEALTH_DATABASE_PORT
  value: {{ .Values.jumper.zoneHealth.databasePort | quote }}
- name: ZONE_HEALTH_DATABASE_INDEX
  value: {{ .Values.jumper.zoneHealth.databaseIndex | quote }}
{{- if and .Values.jumper.zoneHealth.databaseSecretName .Values.jumper.zoneHealth.databaseSecretKey }}
- name: ZONE_HEALTH_DATABASE_PASSWORD
  valueFrom:
   secretKeyRef:
    name: {{ .Values.jumper.zoneHealth.databaseSecretName }}
    key: {{ .Values.jumper.zoneHealth.databaseSecretKey }}
{{- end}}
- name: ZONE_HEALTH_KEY_CHANNEL
  value: {{ .Values.jumper.zoneHealth.keyChannel }}
- name: ZONE_HEALTH_REQUEST_RATE
  value: {{ .Values.jumper.zoneHealth.requestRate | quote }}
- name: ZONE_HEALTH_DEFAULT
  value: {{ .Values.jumper.zoneHealth.defaultHealth | quote }}
- name: ZONE_HEALTH_ENABLED
  value: {{ .Values.jumper.zoneHealth.enabled | quote }}
{{- end}}
- name: JVM_OPTS
  value: {{ .Values.jumper.jvmOpts }}
- name: PUBLISH_EVENT_URL
  value: {{ .Values.jumper.publishEventUrl }}
- name: JUMPER_NAME
  value: {{ .Values.jumper.defaultServiceName | default .Values.global.tracing.defaultServiceName  }}
{{- if .Values.jumper.maxHttpHeaderSize -}}
- name: SERVER_maxHttpHeaderSize
  value: {{ .Values.jumper.maxHttpHeaderSize }}
{{- end -}}
{{- if not (empty .Values.jumper.fpaProxyHost) }}
- name: FPA_PROXY_HOST
  value: {{ .Values.jumper.fpaProxyHost }}
{{- end }}
{{- if not (empty .Values.jumper.fpaProxyPort) }}
- name: FPA_PROXY_PORT
  value: {{ .Values.jumper.fpaProxyPort | quote }}
{{- end }}
{{- if not (empty .Values.jumper.fpaNonProxyHostsRegex) }}
- name: FPA_NON_PROXY_HOSTS_REGEX
  value: {{ .Values.jumper.fpaNonProxyHostsRegex }}
{{- end }}
{{- end -}}

{{- define "kong.customPlugins.env" -}}
{{ $enabledPlugins := "" }}
{{- range .Values.plugins.enabled -}}
{{ $enabledPlugins = printf "%s,%s" $enabledPlugins .  }}
{{- end }}
{{- if eq .Values.plugins.cequence.enabled true }}
{{ $enabledPlugins = printf "%s,%s" $enabledPlugins "cequence-ai-unified" }}
{{- end }}
- name: KONG_PLUGINS
  value: bundled,jwt-keycloak,rate-limiting-merged{{ $enabledPlugins }}
- name: KONG_LUA_PACKAGE_PATH
  value: "/opt/?.lua;;"
{{- end -}}

{{- define "kong.jwtKeycloak.allowedIss" -}}
{{ $allowedIss := "" }}
{{- $failOnUnsetValues := eq (toString .Values.global.failOnUnsetValues) "true" }}
{{- range .Values.plugins.jwtKeycloak.allowedIss -}}
{{- if and ($failOnUnsetValues) (contains "changeme" .) -}}
{{- fail (printf "allowedIss contains changeme") }}
{{- end -}}
{{ $allowedIss = printf "%s,%s" $allowedIss ( . | quote ) }}
{{- end }}
{{- print (trimPrefix "," $allowedIss) }}
{{- end -}}

{{- define "kong.adminApi.host" -}}
{{- if not (empty .Values.adminApi.ingress.hostname) }}
{{- .Values.adminApi.ingress.hostname -}}
{{- else }}
{{- printf "%s-admin-%s.%s" .Release.Name .Release.Namespace .Values.global.domain }}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.serviceHost" -}}
{{- printf "%s-admin.%s" .Release.Name .Release.Namespace }}
{{- end -}}

{{- define "kong.adminApi.name" -}}
admin-api
{{- end -}}

{{- define "kong.adminApi.ingress.path" -}}
{{- if (hasKey .Values "configuration") -}}
/
{{- else -}}
/{{ include "kong.adminApi.name" . }}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.serviceUrl" -}}
{{- $host := include "kong.adminApi.serviceHost" . -}}
{{- if .Values.adminApi.tls.enabled }}
{{- printf "https://%s:%s" $host "8444" }}
{{- else }}
{{- printf "http://%s:%s" $host "8001" }}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.localhost" -}}
{{- $host := "localhost" -}}
{{- if .Values.adminApi.tls.enabled }}
{{- printf "https://%s:%s" $host "8444" }}
{{- else }}
{{- printf "http://%s:%s" $host "8001" }}
{{- end -}}
{{- end -}}

{{- define "kong.proxy.host" -}}
{{- if not (empty .Values.proxy.ingress.hostname) }}
{{- .Values.proxy.ingress.hostname -}}
{{- else }}
{{- printf "%s-%s.%s" .Release.Name .Release.Namespace .Values.global.domain }}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.ingress.enabled" -}}
{{- if and .Values.adminApi.enabled (eq (include "kong.adminApi.ingressDefault" $) "true") }}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.ingressDefault" -}}
{{- if hasKey .Values.adminApi.ingress "enabled" }}
{{- printf "%s" (toString .Values.adminApi.ingress.enabled) -}}
{{- else -}}
{{- printf "true" -}}
{{- end -}}
{{- end -}}

{{- define "kong.merged.adminApi.annotations" }}
{{- $globalAnnotations := dict "annotations" .Values.global.ingress.annotations | deepCopy -}}
{{- $localAnnotations := dict "annotations" .Values.adminApi.ingress.annotations -}}
{{- $mergedAnnotations := mergeOverwrite $globalAnnotations $localAnnotations }}
{{- $mergedAnnotations | toYaml -}}
{{ end -}}

{{- define "kong.merged.proxy.annotations" }}
{{- $globalAnnotations := dict "annotations" .Values.global.ingress.annotations | deepCopy -}}
{{- $localAnnotations := dict "annotations" .Values.proxy.ingress.annotations -}}
{{- $mergedAnnotations := mergeOverwrite $globalAnnotations $localAnnotations }}
{{- $mergedAnnotations | toYaml -}}
{{ end -}}

{{- define "kong.adminApi.ingress.tlsSecret" -}}
{{- if not (and (empty .Values.adminApi.ingress.tlsSecret) (empty .Values.global.ingress.tlsSecret)) -}}
secretName: {{ .Values.adminApi.ingress.tlsSecret | default .Values.global.ingress.tlsSecret -}}
{{- end -}}
{{- end -}}

{{- define "kong.proxy.ingress.tlsSecret" -}}
{{- if not (and (empty .Values.proxy.ingress.tlsSecret) (empty .Values.global.ingress.tlsSecret)) -}}
secretName: {{ .Values.proxy.ingress.tlsSecret | default .Values.global.ingress.tlsSecret -}}
{{- end -}}
{{- end -}}

{{- define "kong.adminApi.ingress.ingressClassName" -}}
{{- if or (include "platformSpecificValue" (list $ . ".Values.adminApi.ingress.ingressClassName")) (include "platformSpecificValue" (list $ . ".Values.global.ingress.ingressClassName")) -}}
ingressClassName: {{ include "platformSpecificValue" (list $ . ".Values.adminApi.ingress.ingressClassName") | default (include "platformSpecificValue" (list $ . ".Values.global.ingress.ingressClassName")) }}
{{- end -}}
{{- end -}}

{{- define "kong.proxy.ingress.ingressClassName" -}}
{{- if or (include "platformSpecificValue" (list $ . ".Values.proxy.ingress.ingressClassName")) (include "platformSpecificValue" (list $ . ".Values.global.ingress.ingressClassName")) -}}
ingressClassName: {{ include "platformSpecificValue" (list $ . ".Values.proxy.ingress.ingressClassName") | default (include "platformSpecificValue" (list $ . ".Values.global.ingress.ingressClassName")) }}
{{- end -}}
{{- end -}}

{{- define "kong.irixBrokerRoute.spacegateHost" -}}
{{- if .Values.irixBrokerRoute.host -}}
{{ .Values.irixBrokerRoute.host -}}
{{- else -}}
{{- include "kong.proxy.host" . -}}
{{- end -}}
{{- end -}}

{{- define "kong.irixBrokerRoute.upstreamHost" -}}
{{- if .Values.irixBrokerRoute.upstream.host -}}
{{ .Values.irixBrokerRoute.upstream.host -}}
{{- else -}}
{{- if .Values.irixBrokerRoute.upstream.namespace -}}
{{ .Values.irixBrokerRoute.upstream.service | default "iris-broker" }}.{{ .Values.irixBrokerRoute.upstream.namespace -}}
{{- else -}}
{{ .Values.irixBrokerRoute.upstream.service | default "iris-broker" }}.{{ .Release.Namespace -}}
{{- end -}}
{{- end -}}
{{- end -}}
