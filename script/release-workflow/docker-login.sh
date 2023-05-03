#!/bin/sh

set -euo >/dev/null

if [ -n "$DOCKER_HUB_USERNAME" ]; then
  echo ${DOCKER_HUB_TOKEN} | docker login --username ${DOCKER_HUB_USERNAME} --password-stdin
else
  echo "Cannot log in to Docker as DOCKER_HUB_USERNAME is not set"
fi
