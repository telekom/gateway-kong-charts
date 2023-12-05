{{- define "common.status-monitor.labels" -}}
tardis.telekom.de/cluster: {{ .Values.global.cluster | default "Default" | quote }}
tardis.telekom.de/namespace: {{ .Release.Namespace | default "Undefined" | quote }}
tardis.telekom.de/team: {{ .Values.global.team | default "io" | quote }}
tardis.telekom.de/product: {{ .Values.global.product | default .Chart.Name | quote }}
{{- end -}}

{{- define "status-monitor.labels" -}}
tardis.telekom.de/subproduct: {{ .Release.Name | quote }}
{{- end -}}

{{- define "database.status-monitor.labels" -}}
tardis.telekom.de/product: {{ .Values.global.product | default .Chart.Name | quote }}
{{- end -}}
