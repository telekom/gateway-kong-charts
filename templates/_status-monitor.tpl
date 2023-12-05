{{- define "common.status-monitor.labels" -}}
tardis.telekom.de/cluster: {{ .Values.global.cluster | default "Default" | quote }}
tardis.telekom.de/namespace: {{ .Release.Namespace | default "Undefined" | quote }}
tardis.telekom.de/product: {{ .Values.global.product | default .Chart.Name | quote }}
tardis.telekom.de/team: {{ .Values.global.team | default "io" | quote }}
tardis.telekom.de/environment: {{ include "status-monitor.environment" . }}
{{- end -}}

{{- define "status-monitor.environment" -}}
{{ .Values.global.metadata.environment | default .Values.global.environment  | default "default" | quote  }}
{{- end -}}

{{- define "status-monitor.labels" -}}
tardis.telekom.de/subproduct: {{ .Release.Name | quote }}
{{- end -}}

{{- define "database.status-monitor.labels" -}}
tardis.telekom.de/subproduct: {{ printf "%s-%s" .Release.Name "database" | quote }}
{{- end -}}
