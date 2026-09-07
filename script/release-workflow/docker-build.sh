#!/bin/sh

set -euo >/dev/null

## This will allow for local use for testing or scanning with trivy (multi-manifest builds cannot be imported)
## we will build a multi-manifest build during ./docker-push.sh
ARCHES=${ARCHES:-'amd64'}
: "${IS_DEBIAN:=}"
DOCKER_IMAGE_ORG_AND_NAME="${DOCKER_REPOSITORY:-pactfoundation}/pact-broker"

## Dockerfile ends with the build-time contract stage, so the published image
## needs an explicit target. Dockerfile.debian is single-stage and ends at
## pb-dev.
TARGET=${IS_DEBIAN:+pb-dev}
TARGET=${TARGET:-runtime}

for arch in $ARCHES; do
  docker buildx build \
    --platform linux/$arch \
    --target ${TARGET} \
    --build-arg VERSION="${TAG:-dev}" \
    --output type=docker \
    --tag ${DOCKER_IMAGE_ORG_AND_NAME}:latest-${arch}${IS_DEBIAN:+"-debian"} \
    -f Dockerfile${IS_DEBIAN:+.debian} \
    .
done
