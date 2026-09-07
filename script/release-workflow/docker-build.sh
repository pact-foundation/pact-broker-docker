#!/bin/sh

set -euo >/dev/null

## Builds a single-platform image into the local image store, for testing and
## for scanning with trivy, neither of which can take a multi-platform index.
ARCHES=${ARCHES:-'amd64'}
: "${IS_DEBIAN:=}"
DOCKER_IMAGE_ORG_AND_NAME="${DOCKER_REPOSITORY:-pactfoundation}/pact-broker"

DISTRO=alpine
if [ -n "${IS_DEBIAN}" ]; then
  DISTRO=debian
fi

for arch in $ARCHES; do
  docker buildx build \
    --platform linux/$arch \
    --target runtime \
    --build-arg DISTRO="${DISTRO}" \
    --build-arg VERSION="${TAG:-dev}" \
    --output type=docker \
    --tag ${DOCKER_IMAGE_ORG_AND_NAME}:latest-${arch}${IS_DEBIAN:+"-debian"} \
    -f Dockerfile \
    .
done
