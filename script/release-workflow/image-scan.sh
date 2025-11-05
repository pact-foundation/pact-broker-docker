#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

ARCH=${ARCH:-'amd64'}
trivy image ${DOCKER_IMAGE_ORG_AND_NAME}:latest-${ARCH} --exit-code 1 --ignorefile ${script_dir}/../.trivyignore
