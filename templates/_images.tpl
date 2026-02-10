{{/*
SPDX-FileCopyrightText: 2023-2026 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Image helpers for all container images used in the chart.
All helpers follow the naming pattern: images.<component>
*/}}

{{/*
Generic image builder helper that constructs image reference with cascading global/override pattern.
Usage: include "images.build" (dict "root" $ "imageConfig" .Values.<component>.image)
*/}}
{{- define "images.build" -}}
{{- $registry := .imageConfig.registry | default .root.Values.global.image.registry -}}
{{- $namespace := .imageConfig.namespace | default .root.Values.global.image.namespace -}}
{{- $repository := .imageConfig.repository -}}
{{- $tag := .imageConfig.tag -}}
{{- printf "%s/%s/%s:%s" $registry $namespace $repository $tag -}}
{{- end -}}

{{- define "images.kong" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.image) -}}
{{- end -}}

{{- define "images.job" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.job.image) -}}
{{- end -}}

{{- define "images.jumper" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.jumper.image) -}}
{{- end -}}

{{- define "images.issuerService" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.issuerService.image) -}}
{{- end -}}

{{- define "images.circuitbreaker" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.circuitbreaker.image) -}}
{{- end -}}

{{- define "images.postgresql" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.postgresql.image) -}}
{{- end -}}

{{- define "images.cosign" -}}
{{- include "images.build" (dict "root" . "imageConfig" .Values.imageVerification.image) -}}
{{- end -}}
