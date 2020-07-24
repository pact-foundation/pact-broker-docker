#!/bin/sh

set -euo >/dev/null

docker build -t ${DOCKER_IMAGE_ORG_AND_NAME}:latest .
