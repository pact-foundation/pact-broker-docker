#!/usr/bin/env sh

set -e

source script/docker-functions

docker_build_bundle_base
bundle_update_on_docker

unset PACT_BROKER_DATABASE_HOST
unset PACT_BROKER_DATABASE_USERNAME
unset PACT_BROKER_DATABASE_PASSWORD
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test.sh
PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test_basic_auth.sh
git add pact_broker
git commit -m "feat(gems): update pact_broker gem to version $(get_pact_broker_version)"
git push
