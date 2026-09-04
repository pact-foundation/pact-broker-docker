#!/bin/sh

# Derives the Docker tags for a release.
#
# If TAG is set, it is used verbatim and nothing else is derived. This is the
# non-production path, for pushing a one-off image.
#
# Otherwise the tag is composed from the VERSION file, which script/release.rb
# wrote in the release PR, and the pact_broker gem version in the lockfile.

set -e

export DOCKER_IMAGE_ORG_AND_NAME="${DOCKER_REPOSITORY:-pactfoundation}/pact-broker"
if [ -n "${DOCKER_TARGET_PLATFORM:-}" ]; then
  ARCH=$(echo "$DOCKER_TARGET_PLATFORM" | sed 's/linux\///' | sed 's/\/v.*//')
  export ARCH
  export ARCHES=$ARCH
else
  export ARCHES='amd64 arm64 arm'
  export ARCH=amd64
fi

: "${IS_DEBIAN:=}"
export IS_DEBIAN=$IS_DEBIAN
export DEBIAN=${IS_DEBIAN:+"-debian"}
echo "IS_DEBIAN=$IS_DEBIAN"

# docker-push.sh reads this under `set -u`, and it is no longer supplied by a
# workflow input.
if [ -z "${TAG:-}" ]; then
  : "${PUSH_TO_LATEST:=true}"
  export PUSH_TO_LATEST

  VERSION=$(cat VERSION)
  export VERSION
  PACT_BROKER_VERSION=$(grep "pact_broker (" pact_broker/Gemfile.lock | awk -F '[()]' '{print $2}')
  export PACT_BROKER_VERSION
  export TAG="$VERSION-pactbroker${PACT_BROKER_VERSION}"
  MAJOR_TAG=$(echo "$VERSION" | cut -d'.' -f1)
  export MAJOR_TAG

  echo "VERSION=$VERSION"
  echo "PACT_BROKER_VERSION=$PACT_BROKER_VERSION"
  echo "TAG=$TAG"
  echo "MAJOR_TAG=$MAJOR_TAG"
else
  # A one-off TAG push must not overwrite `latest` unless explicitly asked.
  : "${PUSH_TO_LATEST:=false}"
  export PUSH_TO_LATEST

  echo "TAG=$TAG"
fi
