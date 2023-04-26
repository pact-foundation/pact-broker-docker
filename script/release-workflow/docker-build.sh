#!/bin/sh

set -euo >/dev/null

DOCKER_TARGET_PLATFORM=${DOCKER_TARGET_PLATFORM:-"linux/amd64"}

docker buildx build --platform=${DOCKER_TARGET_PLATFORM} -t ${DOCKER_IMAGE_ORG_AND_NAME}:latest . --load
