#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

. ${script_dir}/set-env-vars.sh

${script_dir}/docker-build.sh
${script_dir}/../scan-image.sh "${DOCKER_IMAGE_ORG_AND_NAME}:latest-${ARCH}${IS_DEBIAN:+-debian}"
