#!/bin/sh

# SPDX-FileCopyrightText: 2026 Deutsche Telekom AG
#
# SPDX-License-Identifier: Apache-2.0

set -eu

manifest=$1
mode=$2
expected_ingress_port=$3

curl_count=$(grep -Ec '(^|[=`[:space:]])curl[[:space:]]' "$manifest")
# shellcheck disable=SC2016 # Match the literal variable expansion in rendered scripts.
curl_opts_pattern='curl[[:space:]]+\$CURL_OPTS([[:space:]]|$)'
curl_opts_count=$(grep -Ec "$curl_opts_pattern" "$manifest")

if [ "$curl_count" -eq 0 ] || [ "$curl_count" -ne "$curl_opts_count" ]; then
  printf 'Expected every rendered curl to expand CURL_OPTS, found %s of %s\n' "$curl_opts_count" "$curl_count" >&2
  exit 1
fi

curl_env_count=$(awk '
  /- name: CURL_OPTS/ {
    getline
    count++
    if ($0 ~ expected) matches++
  }
  END {
    print count ":" matches
  }
' expected="value: \"$(if [ "$mode" = insecure ]; then printf '%s' --insecure; fi)\"" "$manifest")

if [ "$curl_env_count" != "7:7" ]; then
  printf 'Expected seven CURL_OPTS values for %s mode, found %s\n' "$mode" "$curl_env_count" >&2
  exit 1
fi

grep -q '"protocol": "https"' "$manifest"
grep -q '"port": 8444' "$manifest"

if [ "$mode" = insecure ]; then
  grep -q '"tls_verify": false' "$manifest"
else
  grep -q '"tls_verify": true' "$manifest"
  if grep -q -- '--insecure' "$manifest"; then
    printf 'Secure mode rendered --insecure\n' >&2
    exit 1
  fi
fi

actual_ingress_port=$(awk '
  /# Source: stargate\/templates\/ingress-admin.yml/ { in_admin_ingress=1; next }
  in_admin_ingress && /^---$/ { exit }
  in_admin_ingress && /^[[:space:]]+port:$/ {
    getline
    print $2
    exit
  }
' "$manifest")

if [ "$actual_ingress_port" != "$expected_ingress_port" ]; then
  printf 'Expected Admin Ingress backend port %s, found %s\n' "$expected_ingress_port" "$actual_ingress_port" >&2
  exit 1
fi
