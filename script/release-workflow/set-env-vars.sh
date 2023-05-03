#!/bin/sh

# If TAG is set, no more environment variables are set. The VERSION file will not be updated during release.
# If only INCREMENT is set, then the TAG, MAJOR_TAG and MINOR_TAG are calculated
# If VERSION and INCREMENT are set, then the TAG, MAJOR_TAG and MINOR_TAG are calculated

set -e

export DOCKER_IMAGE_ORG_AND_NAME="${DOCKER_REPOSITORY:-pactfoundation}/pact-broker"

if [ -z "$TAG" ]; then
  if [ -n "$VERSION" ] && [ -z "$INCREMENT" ]; then
    echo "If VERSION is specified, then INCREMENT must also be specified"
    exit 1
  fi

  export INCREMENT=${INCREMENT:-minor}

  if [ -z "$VERSION" ]; then
    export VERSION=$(bundle exec bump show-next $INCREMENT)
  fi

  export PACT_BROKER_VERSION=$(grep "pact_broker (" pact_broker/Gemfile.lock | awk -F '[()]' '{print $2}')
  export TAG="$VERSION-pactbroker${PACT_BROKER_VERSION}"
  export MAJOR_TAG="$(echo $VERSION | cut -d'.' -f1)"

  echo "INCREMENT=$INCREMENT"
  echo "VERSION=$VERSION"
  echo "PACT_BROKER_VERSION=$PACT_BROKER_VERSION"
  echo "TAG=$TAG"
  echo "MAJOR_TAG=$MAJOR_TAG"
else
  echo "TAG=$TAG"
fi
