#!/bin/sh
# Builds the contract target, which asserts at build time that no build
# tooling survived into the runtime image.

set -eu

DISTRO="${DISTRO:-alpine}"
PLATFORM="${PLATFORM:-linux/amd64}"

docker buildx build \
  --platform "${PLATFORM}" \
  --build-arg DISTRO="${DISTRO}" \
  --target contract \
  --output type=cacheonly \
  -f Dockerfile \
  .

echo "PASS: contract holds for ${DISTRO} on ${PLATFORM}"
