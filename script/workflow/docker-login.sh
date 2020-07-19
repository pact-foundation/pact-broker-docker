#!/bin/sh

set -euo

echo ${DOCKER_HUB_TOKEN} | docker login --username ${DOCKER_HUB_USERNAME} --password-stdin
