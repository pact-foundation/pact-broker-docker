#!/bin/sh

set -e

: "${TAG:?TAG must be provided}"
: "${IS_DEBIAN:=}"
DEBIAN=${IS_DEBIAN:+"-debian"}

PACT_BROKER_IMAGE="pactfoundation/pact-broker:${TAG}${DEBIAN}"
export PACT_BROKER_IMAGE
echo "Testing ${PACT_BROKER_IMAGE}"

cleanup() {
  docker compose -f docker-compose-tests.yml rm -fv || true
  docker compose -f docker-compose-test-different-env-var-names.yml rm -fv || true
}
trap cleanup EXIT

cleanup

docker compose -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
cleanup

export PACT_BROKER_BASIC_AUTH_USERNAME=foo
export PACT_BROKER_BASIC_AUTH_PASSWORD=bar
export PACT_BROKER_PUBLIC_HEARTBEAT=true
docker compose -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

unset PACT_BROKER_BASIC_AUTH_USERNAME
unset PACT_BROKER_BASIC_AUTH_PASSWORD
unset PACT_BROKER_PUBLIC_HEARTBEAT

docker compose -f docker-compose-test-different-env-var-names.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
