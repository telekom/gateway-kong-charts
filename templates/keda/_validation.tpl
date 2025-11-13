{{/*
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
SPDX-FileCopyrightText: 2025 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
KEDA Autoscaling Validation
*/}}
{{- define "keda.validate" -}}
{{- /* Validation 1: Mutual exclusion of HPA and KEDA */ -}}
{{- if and .Values.hpaAutoscaling.enabled .Values.kedaAutoscaling.enabled -}}
{{- fail "ERROR: Cannot enable both hpaAutoscaling (HPA) and kedaAutoscaling (KEDA). Please enable only one." -}}
{{- end -}}

{{- /* Validation 2: minReplicas <= maxReplicas */ -}}
{{- if .Values.kedaAutoscaling.enabled -}}
{{- if gt .Values.kedaAutoscaling.minReplicas .Values.kedaAutoscaling.maxReplicas -}}
{{- fail (printf "ERROR: kedaAutoscaling.minReplicas (%d) must be less than or equal to maxReplicas (%d)" (int .Values.kedaAutoscaling.minReplicas) (int .Values.kedaAutoscaling.maxReplicas)) -}}
{{- end -}}

{{- /* Validation 3: Prometheus serverAddress required when prometheus trigger enabled */ -}}
{{- if .Values.kedaAutoscaling.triggers.prometheus.enabled -}}
{{- if not .Values.kedaAutoscaling.triggers.prometheus.serverAddress -}}
{{- fail "ERROR: kedaAutoscaling.triggers.prometheus.serverAddress is required when prometheus trigger is enabled" -}}
{{- end -}}
{{- if not .Values.kedaAutoscaling.triggers.prometheus.authentication.name -}}
{{- fail "ERROR: kedaAutoscaling.triggers.prometheus.authentication.name is required when prometheus trigger is enabled" -}}
{{- end -}}
{{- end -}}

{{- /* Validation 4: At least one trigger must be enabled */ -}}
{{- $hasCpuTrigger := and .Values.kedaAutoscaling.triggers.cpu.enabled (or .Values.kedaAutoscaling.triggers.cpu.containers.kong.enabled (and .Values.jumper.enabled .Values.kedaAutoscaling.triggers.cpu.containers.jumper.enabled) (and .Values.issuerService.enabled .Values.kedaAutoscaling.triggers.cpu.containers.issuerService.enabled)) -}}
{{- $hasMemoryTrigger := and .Values.kedaAutoscaling.triggers.memory.enabled (or .Values.kedaAutoscaling.triggers.memory.containers.kong.enabled (and .Values.jumper.enabled .Values.kedaAutoscaling.triggers.memory.containers.jumper.enabled) (and .Values.issuerService.enabled .Values.kedaAutoscaling.triggers.memory.containers.issuerService.enabled)) -}}
{{- $hasEnabledTrigger := or $hasCpuTrigger $hasMemoryTrigger .Values.kedaAutoscaling.triggers.prometheus.enabled .Values.kedaAutoscaling.triggers.cron.enabled -}}
{{- if not $hasEnabledTrigger -}}
{{- fail "ERROR: At least one kedaAutoscaling trigger must be enabled with at least one container configured (cpu, memory, prometheus, or cron)" -}}
{{- end -}}
{{- end -}}
{{- end -}}
