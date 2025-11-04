{{/*
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Argo Rollouts helper templates for the stargate chart
*/}}

{{/*
Validates Argo Rollouts configuration
*/}}
{{- define "argoRollouts.validate" -}}
{{- if .Values.argoRollouts.enabled }}
  {{- if and .Values.hpaAutoscaling.enabled }}
    {{- fail "argoRollouts.enabled and hpaAutoscaling.enabled cannot both be true. Please disable one." }}
  {{- end }}
  {{- if .Values.argoRollouts.analysisTemplates.enabled }}
    {{- if and .Values.argoRollouts.analysisTemplates.errorRate.enabled (not .Values.argoRollouts.analysisTemplates.errorRate.prometheusAddress) }}
      {{- fail "argoRollouts.analysisTemplates.errorRate.prometheusAddress is required when error rate analysis is enabled" }}
    {{- end }}
    {{- if and .Values.argoRollouts.analysisTemplates.successRate.enabled (not .Values.argoRollouts.analysisTemplates.successRate.prometheusAddress) }}
      {{- fail "argoRollouts.analysisTemplates.successRate.prometheusAddress is required when success rate analysis is enabled" }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}