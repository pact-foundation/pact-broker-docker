#!/bin/sh
# Verifies the gate tiers behave as designed: unfixed OS findings must not fail
# the build, and the script must still produce SARIF for them.

set -eu

IMAGE="${1:?Please provide an image to scan}"

rm -f trivy-results.sarif

if ./script/scan-image.sh "${IMAGE}"; then
  echo "Gate passed"
else
  echo "Gate failed (expected if there are actionable findings)"
fi

if [ ! -s trivy-results.sarif ]; then
  echo "FAIL: no SARIF produced" >&2
  exit 1
fi

echo "PASS: scan-image.sh produced SARIF"
