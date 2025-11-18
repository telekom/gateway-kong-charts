{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Common base labels set on all resources deployed by the chart.
Includes user specified labels from .Values.global.labels.
*/}}
{{- define "common.labels.base" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: o28m
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- if .Values.global.labels }}
{{ .Values.global.labels | toYaml }}
{{- end -}}
{{- end -}}

{{- define "common.labels.classification" -}}
ei.telekom.de/zone: {{ .Values.global.zone }}
ei.telekom.de/environment: {{ .Values.global.environment }}
{{- end -}}

{{/*
Selector labels for app resources.
These labels are used as selectors and must be stable (immutable).
*/}}
{{- define "app.labels.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}-kong
{{- end }}


{{/*
Standard labels to be set on all app resources (e.g. excluding the DB).
Combines selector labels, base labels and a component label.
*/}}
{{- define "app.labels.standard" -}}
{{- include "app.labels.selectorLabels" . }}
{{ include "common.labels.base" . }}
{{ include "common.labels.classification" . }}
app.kubernetes.io/component: api-gateway
{{- end -}}

{{/*
Image pull secrets.
*/}}
{{- define "image_pull_secrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
{{- if not (kindIs "string" .) }}
  - name: {{ $.Release.Name }}-{{ .name }}
{{- else }}
  - name: {{ . }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "database.host" -}}
  {{- if and (eq .Values.global.database.location "external") .Values.externalDatabase.host  -}}
    {{- .Values.externalDatabase.host -}}
  {{- else -}}
    {{ .Release.Name -}}-postgresql
  {{- end -}}
{{- end -}}

{{- define "argo.pathToSecret" -}}
{{- if .Values.global.pathToSecret -}}
avp.kubernetes.io/path: {{ .Values.global.pathToSecret }}
{{- end -}}
{{- end -}}
