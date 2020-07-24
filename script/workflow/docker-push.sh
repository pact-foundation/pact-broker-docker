#!/bin/sh

set -euo >/dev/null

if [ -n "${MAJOR_TAG}" ]; then
  docker tag ${DOCKER_IMAGE_ORG_AND_NAME}:latest ${DOCKER_IMAGE_ORG_AND_NAME}:${MAJOR_TAG}
  docker push ${DOCKER_IMAGE_ORG_AND_NAME}:${MAJOR_TAG}
  docker push ${DOCKER_IMAGE_ORG_AND_NAME}:latest
fi

docker tag ${DOCKER_IMAGE_ORG_AND_NAME}:latest ${DOCKER_IMAGE_ORG_AND_NAME}:${TAG}
docker push ${DOCKER_IMAGE_ORG_AND_NAME}:${TAG}
