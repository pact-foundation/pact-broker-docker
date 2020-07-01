#!/usr/bin/env sh

set -e

source script/docker-functions
source script/functions

git pull origin master

docker_build_bundle_base
bundle_update_on_docker $1

script/spec.sh
script/test.sh
git add pact_broker
git commit -m "feat(gems): update pact_broker gem to version $(gem_version_from_gemfile_lock)"
