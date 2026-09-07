#!/bin/sh

set -euo >/dev/null

## Dockerfile ends with the build-time contract stage, so the published image
## needs an explicit target. Dockerfile.debian is single-stage and ends at
## pb-dev.
TARGET=${IS_DEBIAN:+pb-dev}
TARGET=${TARGET:-runtime}

## Publish a multi arch build
## ($TAG||$MAJOR_TAG||$LATEST)
push() {
  ## These will use cached builds, so wont build every time.
  docker buildx build --platform=linux/amd64,linux/arm64,linux/arm \
    --build-arg VERSION=${TAG} \
    --target ${TARGET} \
    --annotation "org.opencontainers.image.source=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY" \
    --annotation "org.opencontainers.image.revision=$GITHUB_SHA" \
    --output=type=image,push=true \
    -t ${DOCKER_IMAGE_ORG_AND_NAME}:$1 \
    -f Dockerfile${IS_DEBIAN:+.debian} .

}
push_ghcr() {
  docker buildx build --platform=linux/amd64,linux/arm64,linux/arm \
    --build-arg VERSION=${TAG} \
    --target ${TARGET} \
    --output=type=image,push=true \
    -t "ghcr.io/$(echo "$DOCKER_IMAGE_ORG_AND_NAME" | sed 's/pactfoundation/pact-foundation/g')":$1 \
    -f Dockerfile${IS_DEBIAN:+.debian} .
}

if [ -n "${MAJOR_TAG:-}" ]; then
  push ${MAJOR_TAG}${DEBIAN}
  push_ghcr ${MAJOR_TAG}${DEBIAN}
fi

push ${TAG}${DEBIAN}
push_ghcr ${TAG}${DEBIAN}
if [ "${PUSH_TO_LATEST}" != "false" ]; then
  push latest${DEBIAN}
  push_ghcr latest${DEBIAN}
fi
