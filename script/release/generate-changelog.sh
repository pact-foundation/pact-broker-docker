#!/usr/bin/env sh

set -e

: "${TAG:?Please set the TAG environment variable}"

source script/docker-functions

docker_build_package_base

$(dirname "$0")/prepare-git-log-extract-for-conventional-changelog.sh

docker run --rm -it \
  -e TAG=${TAG} \
  -v ${PWD}/tmp/git-log:/tmp/git-log \
  -v ${PWD}/CHANGELOG.md:/app/CHANGELOG.md \
  pact_broker_package_base \
  sh -c "bundle exec rake generate_changelog"
