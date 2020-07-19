#!/bin/sh

set -euo pipefail

echo ${DOCKER_HUB_TOKEN} | docker login --username ${DOCKER_HUB_USERNAME} --password-stdin
