{{/*
SPDX-FileCopyrightText: 2023-2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{- define "postgresql.pvcName" -}}
{{- printf "%s-database-pvc" .Release.Name -}}
{{- end -}}


{{- define "postgresql.dbCheck.image" -}}
{{- $imageName := "postgres" -}}
{{- $imageTag := "12.3-debian" -}}
{{- $imageRepository := "mtr.devops.telekom.de" -}}
{{- $imageOrganization := "tardis-common" -}}
{{- if .Values.postgresql.image -}}
  {{- if not (kindIs "string" .Values.postgresql.image) -}}
    {{ $imageRepository = .Values.postgresql.image.repository | default $imageRepository -}}
    {{ $imageOrganization = .Values.postgresql.image.organization | default $imageOrganization -}}
    {{ $imageName = .Values.postgresql.image.name | default $imageName -}}
    {{ $imageTag = .Values.postgresql.image.tag | default $imageTag -}}
    {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
  {{- else -}}
    {{- if .Values.global.image.force -}}
      {{- .Values.postgresql.image | replace "mtr.devops.telekom.de" .Values.global.image.repository | replace "tardis-common" .Values.global.image.organization -}}
    {{- else -}}
      {{- .Values.postgresql.image -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
 {{- printf "%s/%s/%s:%s" $imageRepository $imageOrganization $imageName $imageTag -}}
{{- end -}}
{{- end -}}
