#!/usr/bin/env sh

set -e

if nc -zv localhost 9292 >/dev/null 2>&1 ; then
  echo "ERROR: There another process running on port 9292"
  exit 1
fi

source script/docker-functions
source script/functions

git pull origin master

docker_build_bundle_base
bundle_update_on_docker $1

script/spec.sh
unset PACT_BROKER_DATABASE_HOST
unset PACT_BROKER_DATABASE_USERNAME
unset PACT_BROKER_DATABASE_PASSWORD
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test.sh
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test_basic_auth.sh
git add pact_broker
git commit -m "feat(gems): update pact_broker gem to version $(gem_version_from_gemfile_lock)"
