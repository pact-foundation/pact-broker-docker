#!/bin/sh

export DOCKER_IMAGE_ORG_AND_NAME=pactfoundation/pact-broker

if [ -n "${CUSTOM_TAG:-}" ]; then
  export TAG=$CUSTOM_TAG
  export MAJOR_TAG=""
else
  export TAG=$(script/release/next-docker-tag.sh)
  export MAJOR_TAG=$(echo $TAG | cut -d'.' -f1)
fi

echo "Set TAG=${TAG}"
echo "Set MAJOR_TAG=${MAJOR_TAG}"
