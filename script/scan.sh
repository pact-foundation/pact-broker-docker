#!/bin/bash

set -eu

: "${1?Please provide the image to scan}"
ARCH=${ARCH:-'amd64'}

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)

docker run --rm \
  --platform=linux/${ARCH} \
  -v ${SCRIPT_DIR}/.trivyignore:/pact_broker/.trivyignore \
  -v ${PWD}/script/scan-inside-docker-container.sh:/pact_broker/scan-inside-docker-container.sh \
  -u root \
  --entrypoint /bin/sh \
  "$1" \
  /pact_broker/scan-inside-docker-container.sh
