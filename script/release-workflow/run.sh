#!/bin/sh

set -euo >/dev/null
: "${IS_DEBIAN:=}"

workflow_dir=$(cd "$(dirname $0)" && pwd)

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  ${workflow_dir}/docker-login.sh
fi

. ${workflow_dir}/set-env-vars.sh

${workflow_dir}/docker-prepare.sh
${workflow_dir}/docker-build.sh
${workflow_dir}/docker-scan.sh
${workflow_dir}/docker-push.sh
