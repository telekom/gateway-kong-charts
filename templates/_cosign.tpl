{{/*
SPDX-FileCopyrightText: 2026 Deutsche Telekom AG

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Returns true if image verification is enabled.
*/}}
{{- define "cosign.enabled" -}}
{{- if .Values.imageVerification.enabled -}}
true
{{- end -}}
{{- end -}}

{{/*
Returns a list of all enabled container images for verification.
*/}}
{{- define "cosign.imagesToVerify" -}}
{{- $images := list -}}
{{- $images = append $images (include "images.kong" .) -}}
{{- if .Values.jumper.enabled -}}
{{- $images = append $images (include "images.jumper" .) -}}
{{- end -}}
{{- if .Values.issuerService.enabled -}}
{{- $images = append $images (include "images.issuerService" .) -}}
{{- end -}}
{{- if .Values.circuitbreaker.enabled -}}
{{- $images = append $images (include "images.circuitbreaker" .) -}}
{{- end -}}
{{- $images | toJson -}}
{{- end -}}

{{/*
Validates that exactly one public key source is configured.
*/}}
{{- define "cosign.validatePublicKey" -}}
{{- if .Values.imageVerification.enabled -}}
{{- $source := .Values.imageVerification.publicKey.source -}}
{{- if not (or (eq $source "value") (eq $source "configMap") (eq $source "secret")) -}}
{{- fail "imageVerification.publicKey.source must be one of: value, configMap, secret" -}}
{{- end -}}
{{- if and (eq $source "value") (not .Values.imageVerification.publicKey.value) -}}
{{- fail "imageVerification.publicKey.value is required when source is 'value'" -}}
{{- end -}}
{{- if and (eq $source "configMap") (not .Values.imageVerification.publicKey.configMapRef.name) -}}
{{- fail "imageVerification.publicKey.configMapRef.name is required when source is 'configMap'" -}}
{{- end -}}
{{- if and (eq $source "secret") (not .Values.imageVerification.publicKey.secretRef.name) -}}
{{- fail "imageVerification.publicKey.secretRef.name is required when source is 'secret'" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the key filename to use in the mounted volume.
*/}}
{{- define "cosign.publicKeyFilename" -}}
{{- $source := .Values.imageVerification.publicKey.source -}}
{{- if eq $source "value" -}}
cosign.pub
{{- else if eq $source "configMap" -}}
{{- .Values.imageVerification.publicKey.configMapRef.key -}}
{{- else -}}
{{- .Values.imageVerification.publicKey.secretRef.key -}}
{{- end -}}
{{- end -}}

{{/*
Returns the volume configuration for the cosign public key.
*/}}
{{- define "cosign.keyVolume" -}}
{{- $source := .Values.imageVerification.publicKey.source -}}
- name: cosign-key
{{- if eq $source "value" }}
  configMap:
    name: {{ .Release.Name }}-cosign-public-key
{{- else if eq $source "configMap" }}
  configMap:
    name: {{ .Values.imageVerification.publicKey.configMapRef.name }}
{{- else }}
  secret:
    secretName: {{ .Values.imageVerification.publicKey.secretRef.name }}
{{- end }}
{{- end -}}

{{/*
Returns the InitContainer for cosign image verification.
*/}}
{{- define "cosign.initContainer" -}}
- name: cosign-verify
  image: {{ include "images.cosign" . }}
  imagePullPolicy: {{ .Values.imageVerification.imagePullPolicy | default .Values.global.imagePullPolicy }}
  securityContext: {{ .Values.imageVerification.containerSecurityContext | toYaml | nindent 4 }}
  resources: {{ .Values.imageVerification.resources | toYaml | nindent 4 }}
  env:
  - name: VERIFICATION_MODE
    value: {{ .Values.imageVerification.mode | quote }}
  volumeMounts:
  - name: cosign-key
    mountPath: /cosign
    readOnly: true
  command:
  - /bin/sh
  - -c
  - |
    set -e
    FAILED=0
    IMAGES='{{ include "cosign.imagesToVerify" . }}'

    echo "=== Cosign Image Verification (mode: $VERIFICATION_MODE) ==="

    for IMAGE in $(echo "$IMAGES" | tr -d '[]"' | tr ',' ' '); do
      echo "Verifying: $IMAGE"
      if cosign verify --insecure-ignore-tlog=true --key /cosign/{{ include "cosign.publicKeyFilename" . }} "$IMAGE" 2>&1; then
        echo "✓ $IMAGE: signature valid"
      else
        echo "✗ $IMAGE: signature verification FAILED"
        FAILED=1
      fi
    done

    if [ "$FAILED" -eq 1 ]; then
      echo "=== Verification completed with failures ==="
      if [ "$VERIFICATION_MODE" = "enforce" ]; then
        echo "Mode is 'enforce': blocking pod startup"
        exit 1
      else
        echo "Mode is 'audit': continuing despite failures"
        exit 0
      fi
    fi

    echo "=== All images verified successfully ==="
{{- end -}}
