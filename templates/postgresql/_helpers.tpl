{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{- define "postgresql.labels" -}}
app: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: postgresql
{{ include "postgresql.selector" . }}
app.kubernetes.io/component: database
app.kubernetes.io/part-of: tardis-runtime
{{ .Values.global.labels | toYaml }}
{{- end -}}

{{- define "postgresql.selector" -}}
app.kubernetes.io/instance: {{ .Release.Name }}-postgresql
{{- end -}}

{{- define "postgresql.image" -}}
{{- $imageRegistry := .Values.postgresql.image.registry | default .Values.global.image.registry -}}
{{- $imageNamespace := .Values.postgresql.image.namespace | default .Values.global.image.namespace -}}
{{- $imageRepository := .Values.postgresql.image.repository -}}
{{- $imageTag := .Values.postgresql.image.tag -}}
{{- printf "%s/%s/%s:%s" $imageRegistry $imageNamespace $imageRepository $imageTag -}}
{{- end -}}

{{- define "postgresql.env" }}
- name: PGDATA
  value: {{ .Values.postgresql.persistence.mountDir }}/pgdata
- name: POSTGRES_USER
  value: {{ .Values.global.database.username }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "postgresql.secretName" . }}
      key: databasePassword
- name: POSTGRES_DB
  value: {{ .Values.global.database.database }}
{{- if .Values.postgresql.adminPassword }}
- name: POSTGRES_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "postgresql.secretName" . }}
      key: adminPassword
{{- end }}
- name: POSTGRES_MAX_CONNECTIONS
  value: "{{ .Values.postgresql.maxConnections }}"
- name: POSTGRES_SHARED_BUFFERS
  value: {{ .Values.postgresql.sharedBuffers }}
- name: POSTGRES_MAX_PREPARED_TRANSACTIONS
  value: "{{ .Values.postgresql.maxPreparedTransactions }}"
{{- end -}}

{{- define "postgresql.deploymentName" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{- define "postgresql.pvcName" -}}
{{- printf "%s-database-pvc" .Release.Name -}}
{{- end -}}

{{- define "postgresql.secretName" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{- define "postgresql.serviceName" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
