#!/bin/sh

set -euo >/dev/null

## Publish a multi arch build
## ($TAG||$MAJOR_TAG||$LATEST)
push() {
  ## These will use cached builds, so wont build every time.
  docker buildx build --platform=linux/amd64,linux/arm64,linux/arm \
    --annotation "org.opencontainers.image.source=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY" \
    --annotation "org.opencontainers.image.revision=$GITHUB_SHA" \
    --output=type=image,push=true \
    -t ${DOCKER_IMAGE_ORG_AND_NAME}:$1 .
}
push_ghcr() {
  docker buildx build --platform=linux/amd64,linux/arm64,linux/arm \
  --output=type=image,push=true \
  -t ghcr.io/$(echo $DOCKER_IMAGE_ORG_AND_NAME | sed 's/pactfoundation/pact-foundation/g'):$1 .
}

if [ -n "${MAJOR_TAG:-}" ]; then
  push ${MAJOR_TAG}
  push_ghcr ${MAJOR_TAG}
fi

push ${TAG}
push_ghcr ${TAG}

if [ "${PUSH_TO_LATEST}" != "false" ]; then
  push latest
  push_ghcr latest
fi
