#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

. ${script_dir}/set-env-vars.sh

${script_dir}/docker-build.sh
${script_dir}/image-scan.sh
