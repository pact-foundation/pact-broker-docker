#!/bin/sh

set -eu

## Builds one single-platform image into the local image store, for testing and
## for scanning with trivy, neither of which can take a multi-platform index.
. ./script/distro.sh

ARCH=${ARCH:-amd64}
DOCKER_IMAGE_ORG_AND_NAME="${DOCKER_REPOSITORY:-pactfoundation}/pact-broker"

docker buildx build \
  --platform "linux/${ARCH}" \
  --target runtime \
  --build-arg DISTRO="${DISTRO}" \
  --build-arg VERSION="${TAG:-dev}" \
  --output type=docker \
  --tag "${DOCKER_IMAGE_ORG_AND_NAME}:latest-${ARCH}${TAG_SUFFIX}" \
  -f Dockerfile \
  .
