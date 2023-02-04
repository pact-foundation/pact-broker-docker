#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  ${script_dir}/git-configure.sh
  ${script_dir}/docker-login.sh
fi

. ${script_dir}/set-env-vars.sh

${script_dir}/validate.sh
${script_dir}/docker-build.sh
${script_dir}/docker-scan.sh
${script_dir}/prepare-release.sh
${script_dir}/docker-push.sh
${script_dir}/git-push.sh
