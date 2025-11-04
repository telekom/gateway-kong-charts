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

{{- define "platformSpecificValue" -}}
{{- $ := index . 0 -}}
{{- $template := printf "{{ %s | toYaml }}" (index . 2) -}}
{{- with index . 1 -}}
{{- $value := tpl $template $ -}}

{{- if and (eq $value "null") -}}
{{- $selectedPlatformFile := printf "platforms/%s.yaml" .Values.global.platform -}}
{{- $platformValues := $.Files.Get $selectedPlatformFile | fromYaml -}}
{{ $value = tpl $template (mergeOverwrite (dict "Values" $platformValues) $) }}
{{- end -}}

{{- if not (eq $value "null") -}}
{{ $value }}
{{- end -}}

{{- end -}}
{{- end -}}

{{- define "argo.pathToSecret" -}}
{{- if .Values.global.pathToSecret -}}
avp.kubernetes.io/path: {{ .Values.global.pathToSecret }}
{{- end -}}
{{- end -}}

{{- define "argo.checksum" -}}
{{- $ := index . 0 -}}
{{- $fullKey := index . 2 -}}
{{- $value := tpl (printf "{{ %s }}" $fullKey) $ -}}
{{- with index . 1 -}}
{{- if .Values.global.pathToSecret -}}
{{- $key := splitList "." $fullKey | last -}}
checksum/secret-{{ $key }}: <{{ printf "path:%s#%s" .Values.global.pathToSecret (trimAll "<>" $value) }} | sha256sum>
{{- end -}}
{{- end -}}
{{- end -}}