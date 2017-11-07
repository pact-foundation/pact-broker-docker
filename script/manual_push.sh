#!/bin/bash
# Ripped from https://gist.github.com/didip/ff5088fd023624aba7c0

set -ex

IMAGE_NAME="dius/pact-broker"
TAG=$(script/next-docker-tag.sh)

docker pull ${IMAGE_NAME}
docker build -t ${IMAGE_NAME}:${TAG} .
# docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest
docker push ${IMAGE_NAME}:${TAG}
