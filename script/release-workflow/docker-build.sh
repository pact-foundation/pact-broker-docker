#!/bin/sh

set -euo >/dev/null

## This will allow for local use for testing or scanning with trivy (multi-manifest builds cannot be imported)
## we will build a multi-manifest build during ./docker-push.sh

for arch in $ARCHES; do 
    docker buildx build \
    --platform linux/$arch \
    --output type=docker \
    --tag ${DOCKER_IMAGE_ORG_AND_NAME}:latest-${arch} \
    .
done