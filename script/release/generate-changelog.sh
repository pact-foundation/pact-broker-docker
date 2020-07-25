#!/usr/bin/env sh

set -e

: "${TAG:?Please set the TAG environment variable}"

. script/docker-functions

docker_build_package_base

docker run --rm -it \
  -e TAG=${TAG} \
  -v ${PWD}:/app \
  pact_broker_package_base \
  sh -c "bundle exec rake generate_changelog"
