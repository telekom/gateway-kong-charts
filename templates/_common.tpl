{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
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
