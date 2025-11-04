{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{- define "postgresql.pvcName" -}}
{{- printf "%s-database-pvc" .Release.Name -}}
{{- end -}}


{{- define "postgresql.dbCheck.image" -}}
{{- $imageRegistry := .Values.postgresql.image.registry | default .Values.global.image.registry -}}
{{- $imageNamespace := .Values.postgresql.image.namespace | default .Values.global.image.namespace -}}
{{- $imageRepository := .Values.postgresql.image.repository -}}
{{- $imageTag := .Values.postgresql.image.tag -}}
{{- printf "%s/%s/%s:%s" $imageRegistry $imageNamespace $imageRepository $imageTag -}}
{{- end -}}
