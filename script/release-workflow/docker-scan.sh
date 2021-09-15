#!/bin/sh

set -euo >/dev/null

script_dir=$(cd "$(dirname $0)" && pwd)

${script_dir}/../scan.sh ${DOCKER_IMAGE_ORG_AND_NAME}:latest
