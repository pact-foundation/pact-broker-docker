#!/bin/sh

set -euo >/dev/null
: "${IS_DEBIAN:=}"

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

# skip release prep and git push on the debian workflow to avoid 
# overwriting
if [ -z "${IS_DEBIAN}" ]; then
  ${workflow_dir}/prepare-release.sh
fi
${workflow_dir}/docker-push.sh
if [ -z "${IS_DEBIAN}" ]; then
  ${workflow_dir}/git-push.sh
fi