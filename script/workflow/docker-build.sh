#!/bin/sh

set -euo

docker build -t ${DOCKER_IMAGE_ORG_AND_NAME}:latest .
