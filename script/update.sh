#!/usr/bin/env sh

set -e

. script/docker-functions
. script/functions

git pull origin main

docker_build_bundle_base
bundle_update_on_docker $1

docker build --target runtime -t pactfoundation/pact_broker:latest .

script/spec.sh
script/test.sh
git add pact_broker
git commit -m "feat(deps): update dependency pact_broker to v$(gem_version_from_gemfile_lock)"
