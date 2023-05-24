#!/bin/sh

set -euo >/dev/null

## Publish a multi arch build with -multi added to the tag
## ($TAG||$MAJOR_TAG||$LATEST)-multi
push_multi() {
  ## These will use cached builds, so wont build every time.
  docker buildx build --platform=linux/amd64,linux/arm64,linux/arm \
    --output=type=image,push=true \
    -t ${DOCKER_IMAGE_ORG_AND_NAME}:$1-multi .
}
push() {
  docker buildx build --platform=linux/amd64 \
    --output=type=image,push=true \
    -t ${DOCKER_IMAGE_ORG_AND_NAME}:$1 .
}

if [ -n "${MAJOR_TAG:-}" ]; then
  push ${MAJOR_TAG}
  push_multi ${MAJOR_TAG}
fi

push ${TAG}
push_multi ${TAG}

if [ "${PUSH_TO_LATEST}" != "false" ]; then
  push latest
  push_multi latest
fi