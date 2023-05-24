#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

ARCH=${ARCH:-'amd64'}
${script_dir}/../scan.sh ${DOCKER_IMAGE_ORG_AND_NAME}:latest-${ARCH}
