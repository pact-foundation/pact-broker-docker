#!/bin/sh

set -euo >/dev/null

workflow_dir=$(cd "$(dirname $0)" && pwd)

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  ${workflow_dir}/git-configure.sh
  ${workflow_dir}/docker-login.sh
fi

. ${workflow_dir}/set-env-vars.sh

${workflow_dir}/validate.sh
${workflow_dir}/docker-prepare.sh
${workflow_dir}/docker-build.sh
${workflow_dir}/docker-scan.sh
${workflow_dir}/prepare-release.sh
${workflow_dir}/docker-push.sh
${workflow_dir}/git-push.sh
