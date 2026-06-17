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
Validates that publicKeys is a non-empty list with valid entries.
Each entry must have a valid source and the required fields for that source.
*/}}
{{- define "cosign.validatePublicKeys" -}}
{{- if .Values.imageVerification.enabled -}}
{{- if not .Values.imageVerification.publicKeys -}}
{{- fail "imageVerification.publicKeys must be a non-empty list" -}}
{{- end -}}
{{- range $i, $entry := .Values.imageVerification.publicKeys -}}
{{- $source := $entry.source -}}
{{- if not (or (eq $source "value") (eq $source "configMap") (eq $source "secret")) -}}
{{- fail (printf "imageVerification.publicKeys[%d].source is missing or invalid (got %q); must be one of: value, configMap, secret" $i $source) -}}
{{- end -}}
{{- if and (eq $source "value") (not $entry.value) -}}
{{- fail (printf "imageVerification.publicKeys[%d].value is required when source is 'value'" $i) -}}
{{- end -}}
{{- if and (eq $source "configMap") (not $entry.configMapRef.name) -}}
{{- fail (printf "imageVerification.publicKeys[%d].configMapRef.name is required when source is 'configMap'" $i) -}}
{{- end -}}
{{- if and (eq $source "configMap") (not $entry.configMapRef.key) -}}
{{- fail (printf "imageVerification.publicKeys[%d].configMapRef.key is required when source is 'configMap'" $i) -}}
{{- end -}}
{{- if and (eq $source "secret") (not $entry.secretRef.name) -}}
{{- fail (printf "imageVerification.publicKeys[%d].secretRef.name is required when source is 'secret'" $i) -}}
{{- end -}}
{{- if and (eq $source "secret") (not $entry.secretRef.key) -}}
{{- fail (printf "imageVerification.publicKeys[%d].secretRef.key is required when source is 'secret'" $i) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the volume name for a public key entry.
Accepts: (dict "source" <string> "i" <int> "prefix" <string>)

  source=value     → "<prefix>-cosign-public-key"  (shared ConfigMap; index unused)
  source=configMap → "cosign-key-cm-<i>"
  source=secret    → "cosign-key-sec-<i>"
*/}}
{{- define "cosign.keyVolumeName" -}}
{{- if eq .source "value" -}}
{{- .prefix }}-cosign-public-key
{{- else if eq .source "configMap" -}}
cosign-key-cm-{{ .i }}
{{- else if eq .source "secret" -}}
cosign-key-sec-{{ .i }}
{{- end -}}
{{- end -}}

{{/*
Returns the mount path for a public key entry.
Accepts: (dict "source" <string> "i" <int>)

  source=value     → /cosign/values
  source=configMap → /cosign/cm-<i>
  source=secret    → /cosign/sec-<i>
*/}}
{{- define "cosign.keyMountPath" -}}
{{- if eq .source "value" -}}
/cosign/values
{{- else if eq .source "configMap" -}}
/cosign/cm-{{ .i }}
{{- else if eq .source "secret" -}}
/cosign/sec-{{ .i }}
{{- end -}}
{{- end -}}

{{/*
Returns the volume definitions for all public key entries.
All source=value entries share a single ConfigMap volume (emitted once).
source=configMap and source=secret each get an individual volume per entry.
*/}}
{{- define "cosign.keyVolumes" -}}
{{- $state := dict "hasValueSource" false -}}
{{- range $i, $entry := .Values.imageVerification.publicKeys -}}
{{- $ctx := dict "source" $entry.source "i" $i "prefix" $.Release.Name -}}
{{- if eq $entry.source "value" -}}
{{- if not (get $state "hasValueSource") }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  configMap:
    name: {{ $.Release.Name }}-cosign-public-key
{{- end -}}
{{- $_ := set $state "hasValueSource" true -}}
{{- else if eq $entry.source "configMap" }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  configMap:
    name: {{ $entry.configMapRef.name }}
{{- else if eq $entry.source "secret" }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  secret:
    secretName: {{ $entry.secretRef.name }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the volumeMount entries for all public key entries.
All source=value entries share a single mount (emitted once).
*/}}
{{- define "cosign.keyVolumeMounts" -}}
{{- $state := dict "hasValueSource" false -}}
{{- range $i, $entry := .Values.imageVerification.publicKeys -}}
{{- $ctx := dict "source" $entry.source "i" $i "prefix" $.Release.Name -}}
{{- if eq $entry.source "value" -}}
{{- if not (get $state "hasValueSource") }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  mountPath: {{ include "cosign.keyMountPath" $ctx }}
  readOnly: true
{{- end -}}
{{- $_ := set $state "hasValueSource" true -}}
{{- else if eq $entry.source "configMap" }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  mountPath: {{ include "cosign.keyMountPath" $ctx }}
  readOnly: true
{{- else if eq $entry.source "secret" }}
- name: {{ include "cosign.keyVolumeName" $ctx }}
  mountPath: {{ include "cosign.keyMountPath" $ctx }}
  readOnly: true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the emptyDir volume used as the cosign DOCKER_CONFIG directory.
*/}}
{{- define "cosign.dockerConfigVolume" -}}
- name: cosign-docker-config
  emptyDir: {}
{{- end -}}

{{/*
Returns the volumeMount entry for the cosign DOCKER_CONFIG emptyDir.
*/}}
{{- define "cosign.dockerConfigVolumeMount" -}}
- name: cosign-docker-config
  mountPath: /tmp/docker
{{- end -}}

{{/*
Returns the Secret volume definitions for imagePullSecrets.
*/}}
{{- define "cosign.pullSecretVolumes" -}}
{{- if .Values.global.imagePullSecrets -}}
{{- range $i, $secret := .Values.global.imagePullSecrets -}}
{{- $secretName := "" -}}
{{- if not (kindIs "string" $secret) -}}
{{- $secretName = printf "%s-%s" $.Release.Name $secret.name -}}
{{- else -}}
{{- $secretName = $secret -}}
{{- end }}
- name: pull-secret-{{ $i }}
  secret:
    secretName: {{ $secretName }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the volumeMount entries for imagePullSecrets.
*/}}
{{- define "cosign.pullSecretVolumeMounts" -}}
{{- if .Values.global.imagePullSecrets -}}
{{- range $i, $secret := .Values.global.imagePullSecrets }}
- name: pull-secret-{{ $i }}
  mountPath: /pull-secrets/{{ $i }}
  readOnly: true
{{- end -}}
{{- end -}}
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
  - name: DOCKER_CONFIG
    value: /tmp/docker
  volumeMounts:
  {{- include "cosign.keyVolumeMounts" . | nindent 2 }}
  {{- include "cosign.dockerConfigVolumeMount" . | nindent 2 }}
  {{- include "cosign.pullSecretVolumeMounts" . | nindent 2 }}
  command:
  - /bin/bash
  - -c
  - |
    FAILED=0
    IMAGES='{{ include "cosign.imagesToVerify" . }}'

    echo "=== Cosign Image Verification (mode: $VERIFICATION_MODE) ==="

    # Function to extract auth from docker config for a registry.
    # Handles both plain hostnames and host:port registries.
    extract_auth() {
      CONFIG_FILE="$1"
      REGISTRY="$2"
      # Use jq for reliable JSON parsing if available; fall back to grep.
      if command -v jq >/dev/null 2>&1; then
        jq -r --arg reg "$REGISTRY" '.auths[$reg].auth // empty' "$CONFIG_FILE" 2>/dev/null || true
      else
        # Escape regex metacharacters in REGISTRY for use in a BRE grep pattern.
        ESCAPED_REG=$(printf '%s\n' "$REGISTRY" | sed 's/[.[\*^$]/\\&/g')
        cat "$CONFIG_FILE" | grep -o "\"$ESCAPED_REG\"[^}]*" | grep -o '"auth":"[^"]*"' | cut -d'"' -f4 || true
      fi
    }

    # Extract the registry host (including port if present) from an image reference.
    # e.g. "mtr.devops.telekom.de:443/myimage:tag" -> "mtr.devops.telekom.de:443"
    # e.g. "ghcr.io/myimage:tag" -> "ghcr.io"
    extract_registry() {
      IMAGE_REF="$1"
      # The registry is the first '/'-delimited segment if it looks like a hostname.
      # A hostname contains a '.' (e.g. ghcr.io) or a numeric port suffix (e.g. host:5000).
      # An image:tag without a '/' must NOT be treated as a host:port registry.
      FIRST=$(echo "$IMAGE_REF" | cut -d'/' -f1)
      case "$FIRST" in
        *.*) echo "$FIRST" ;;  # contains a dot → registry hostname
        *:*) # contains a colon — only treat as host:port if the suffix is purely numeric
             PORT="${FIRST##*:}"
             case "$PORT" in
               *[!0-9]*) echo "" ;;   # non-numeric suffix → it's a tag, not a port
               *)         echo "$FIRST" ;;
             esac ;;
        *)   echo "" ;;  # no explicit registry (Docker Hub short-form)
      esac
    }

    # Try to verify an image with a single key file, with registry auth.
    # Returns 0 if verified, 1 if all pull secrets failed with UNAUTHORIZED
    # (auth problem, not a key mismatch), 2 if signature invalid/other failure.
    verify_with_auth() {
      IMAGE="$1"
      KEY_FILE="$2"
      REGISTRY=$(extract_registry "$IMAGE")
      # Docker Hub images have no explicit registry; credentials are stored under the v1 endpoint.
      if [ -z "$REGISTRY" ]; then
        REGISTRY="https://index.docker.io/v1/"
      fi

      # Clear any credentials left over from a previous key iteration.
      rm -f "$DOCKER_CONFIG/config.json"

      AUTH_ATTEMPTED=0
      VERIFY_FAILED=0

      # Try each pull secret for registry auth
      for SECRET_DIR in /pull-secrets/*; do
        [ -d "$SECRET_DIR" ] || continue
        if [ -f "$SECRET_DIR/.dockerconfigjson" ]; then
          CONFIG_FILE="$SECRET_DIR/.dockerconfigjson"
        elif [ -f "$SECRET_DIR/config.json" ]; then
          CONFIG_FILE="$SECRET_DIR/config.json"
        else
          continue
        fi

        AUTH=$(extract_auth "$CONFIG_FILE" "$REGISTRY")
        if [ -n "$AUTH" ]; then
          DECODED=$(echo "$AUTH" | base64 -d 2>/dev/null || true)
          if [ -z "$DECODED" ]; then
            echo "  (warning: auth token for $REGISTRY in $SECRET_DIR is empty or malformed, skipping)"
            continue
          fi
          USERNAME=$(echo "$DECODED" | cut -d':' -f1)
          PASSWORD=$(echo "$DECODED" | cut -d':' -f2-)

          rm -f "$DOCKER_CONFIG/config.json"
          if ! cosign login "$REGISTRY" -u "$USERNAME" -p "$PASSWORD" >/dev/null 2>&1; then
            echo "  (warning: cosign login failed for $REGISTRY with secret in $SECRET_DIR)"
          fi
          AUTH_ATTEMPTED=1

          OUTPUT=$(cosign verify --insecure-ignore-tlog=true --key "$KEY_FILE" "$IMAGE" 2>&1)
          EXIT_CODE=$?

          if [ $EXIT_CODE -eq 0 ]; then
            return 0
          elif [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep -qiE "(UNAUTHORIZED|401 Unauthorized|403 Forbidden|no basic auth credentials|authentication required|access denied)"; then
            echo "  (auth failed with secret in $SECRET_DIR, trying next...)"
            continue
          else
            # Non-auth failure (e.g. signature not found, network error) — try next pull secret
            # in case a later one produces a cleaner result; record the output for diagnostics.
            echo "  (non-auth failure with secret in $SECRET_DIR: $(echo "$OUTPUT" | head -1))"
            VERIFY_FAILED=1
            continue
          fi
        fi
      done

      # All pull secrets tried. Determine failure mode.
      if [ "$AUTH_ATTEMPTED" -eq 1 ] && [ "$VERIFY_FAILED" -eq 0 ]; then
        # Every authenticated attempt was rejected by the registry (auth failure).
        return 1
      elif [ "$VERIFY_FAILED" -eq 1 ]; then
        # At least one attempt authenticated but cosign reported a non-auth failure.
        return 2
      fi

      # No pull secrets configured or none had credentials for this registry —
      # try unauthenticated.
      OUTPUT=$(cosign verify --insecure-ignore-tlog=true --key "$KEY_FILE" "$IMAGE" 2>&1)
      EXIT_CODE=$?
      if [ $EXIT_CODE -eq 0 ]; then
        return 0
      fi
      echo "$OUTPUT"
      return 2
    }

    echo "=== Verifying images ==="
    for IMAGE in $(jq -r '.[]' <<<"$IMAGES"); do
      echo "Verifying: $IMAGE"
      IMAGE_VERIFIED=0
      AUTH_FAILED=0

      # Iterate over all mounted key directories and files.
      # Succeeds (ANY semantics) as soon as one key validates the signature.
      for KEY_DIR in /cosign/values /cosign/cm-* /cosign/sec-*; do
        [ -d "$KEY_DIR" ] || continue
        for KEY_FILE in "$KEY_DIR"/*; do
          [ -f "$KEY_FILE" ] || continue
          verify_with_auth "$IMAGE" "$KEY_FILE"
          RESULT=$?
          if [ $RESULT -eq 0 ]; then
            echo "✓ $IMAGE: signature valid (key: $KEY_FILE)"
            IMAGE_VERIFIED=1
            break 2
          elif [ $RESULT -eq 1 ]; then
            echo "  key $KEY_FILE: registry authentication failed for all pull secrets"
            AUTH_FAILED=1
          else
            echo "  key $KEY_FILE: signature invalid or other failure"
          fi
        done
      done

      if [ "$IMAGE_VERIFIED" -eq 0 ]; then
        if [ "$AUTH_FAILED" -eq 1 ]; then
          echo "✗ $IMAGE: registry authentication failed for all pull secrets and keys — check your imagePullSecrets"
        else
          echo "✗ $IMAGE: no configured key validated the signature"
        fi
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
