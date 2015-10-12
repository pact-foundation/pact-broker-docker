#!/bin/bash
# Ripped from https://gist.github.com/didip/ff5088fd023624aba7c0

# Beth: UNTESTED!!!!

set -ex

[[ -z "$1" ]] && echo "Usage $0 <tag>" && exit 1

TAG="${1}"
IMAGE_NAME="dius/pact_broker"

docker pull ${IMAGE_NAME}
docker build -t ${IMAGE_NAME}:${TAG} .
docker tag -f ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest
docker push ${IMAGE_NAME}
