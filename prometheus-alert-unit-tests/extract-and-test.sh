#!/usr/bin/env bash
#
# extract-and-test.sh
# -------------------
# Proof-of-concept for DTSPO-33474: unit testing Prometheus alerts that are
# deployed as PrometheusRule CRDs via Flux.
#
# promtool's `test rules` command only understands NATIVE Prometheus rule files
# (a top-level `groups:` document). Our alerts live inside PrometheusRule CRDs
# (apiVersion: monitoring.coreos.com/v1) where the rules are nested under
# `.spec.groups`. This script bridges the two:
#
#   1. Extract `.spec` from every PrometheusRule CRD in rules/ into a native
#      rules file under .generated/ using yq.
#   2. Run `promtool test rules` against the test files in tests/.
#
# Everything runs offline - promtool builds a simulated TSDB from the
# `input_series` in each test, so NO cluster, VPN or Key Vault access is needed.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="${SCRIPT_DIR}/rules"
TESTS_DIR="${SCRIPT_DIR}/tests"
GEN_DIR="${SCRIPT_DIR}/.generated"

command -v yq >/dev/null       || { echo "ERROR: yq not found on PATH" >&2; exit 1; }
command -v promtool >/dev/null || { echo "ERROR: promtool not found on PATH" >&2; exit 1; }

mkdir -p "${GEN_DIR}"

echo "==> Extracting PrometheusRule CRDs -> native rules files"
for crd in "${RULES_DIR}"/*.yaml; do
  base="$(basename "${crd}" .yaml)"
  out="${GEN_DIR}/${base}.rules.yaml"
  # Verify the file is actually a PrometheusRule before extracting.
  kind="$(yq eval '.kind' "${crd}")"
  if [[ "${kind}" != "PrometheusRule" ]]; then
    echo "    skipping ${crd} (kind=${kind}, not a PrometheusRule)"
    continue
  fi
  # `.spec` of a PrometheusRule IS a valid native rules document (it has the
  # `groups:` key), so extracting the spec is all that is required.
  yq eval '.spec' "${crd}" > "${out}"
  echo "    ${crd}  ->  ${out}"
done

echo "==> Validating extracted rule syntax with promtool"
promtool check rules "${GEN_DIR}"/*.rules.yaml

echo "==> Running unit tests"
# Run from the tests dir so the relative rule_files paths resolve.
cd "${TESTS_DIR}"
promtool test rules ./*_test.yaml
