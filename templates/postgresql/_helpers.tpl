{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Selector labels for PostgreSQL resources.
These labels are used for Service selectors and must be stable (immutable).
*/}}
{{- define "postgresql.labels.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}-postgresql
{{- end }}

{{/*
Standard labels for PostgreSQL resources.
Combines selector labels, base labels and a component label.
*/}}
{{- define "postgresql.labels.standard" -}}
{{- include "postgresql.labels.selectorLabels" . }}
{{ include "common.labels.base" . }}
{{ include "common.labels.classification" . }}
app.kubernetes.io/component: database
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
