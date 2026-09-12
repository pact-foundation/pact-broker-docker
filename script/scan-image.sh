#!/bin/sh
# Scans an image in three tiers.
#
# Trivy cannot distinguish packages we installed from packages the base image
# brought, so the gate keys on whether a fix exists, which is a close proxy:
# a fixable finding is one a rebuild or a version bump resolves.

set -eu

IMAGE="${1:?Please provide an image to scan}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
IGNOREFILE="${SCRIPT_DIR}/.trivyignore.yaml"

# A registry reference can resolve to an index holding several platforms, and
# Trivy would otherwise pick the one matching the host. The release scans a
# foreign platform on an emulated leg, so it names the platform explicitly.
PLATFORM_ARG=""
if [ -n "${2:-}" ]; then
  PLATFORM_ARG="--platform $2"
fi

status=0

echo "== Tier 1: gems and vendored binaries =="
# No --ignore-unfixed. An unfixed advisory in pact_broker, puma or rack is
# exactly the case that warrants a human decision, recorded as a dated entry.
trivy image "${IMAGE}" ${PLATFORM_ARG} \
  --scanners vuln \
  --pkg-types library \
  --severity HIGH,CRITICAL \
  --ignorefile "${IGNOREFILE}" \
  --exit-code 1 \
  --no-progress || status=1

echo "== Tier 2: OS packages with an available fix =="
# --ignore-unfixed here: an unfixed distribution CVE affords no decision at all.
trivy image "${IMAGE}" ${PLATFORM_ARG} \
  --scanners vuln \
  --pkg-types os \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --ignorefile "${IGNOREFILE}" \
  --exit-code 1 \
  --no-progress || status=1

echo "== Tier 3: full report, no gate =="
trivy image "${IMAGE}" ${PLATFORM_ARG} \
  --scanners vuln \
  --format sarif \
  --output trivy-results.sarif \
  --exit-code 0 \
  --no-progress

exit "${status}"
