#!/bin/sh

set -e

: "${TAG:?TAG must be provided}"
: "${IS_DEBIAN:=}"
DEBIAN=${IS_DEBIAN:+"-debian"}

PACT_BROKER_IMAGE="pactfoundation/pact-broker:${TAG}${DEBIAN}"
export PACT_BROKER_IMAGE
echo "Testing ${PACT_BROKER_IMAGE}"

# Every compose file gets its own Compose project name. Without this they all
# default to the directory name and share one project, so Compose can reuse a
# still-running container (e.g. postgres) from a previous suite instead of
# starting fresh, leaking state between suites.
cleanup() {
  docker compose -p pact-broker-tests -f docker-compose-tests.yml rm -fv || true
  docker compose -p pact-broker-env-var-names -f docker-compose-test-different-env-var-names.yml rm -fv || true
  docker compose -p pact-broker-clean -f docker-compose-test-clean.yml rm -fv || true
}
trap cleanup EXIT

cleanup

docker compose -p pact-broker-tests -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
cleanup

export PACT_BROKER_BASIC_AUTH_USERNAME=foo
export PACT_BROKER_BASIC_AUTH_PASSWORD=bar
export PACT_BROKER_PUBLIC_HEARTBEAT=true
docker compose -p pact-broker-tests -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

unset PACT_BROKER_BASIC_AUTH_USERNAME
unset PACT_BROKER_BASIC_AUTH_PASSWORD
unset PACT_BROKER_PUBLIC_HEARTBEAT

docker compose -p pact-broker-env-var-names -f docker-compose-test-different-env-var-names.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

docker compose -p pact-broker-clean -f docker-compose-test-clean.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
docker compose -p pact-broker-clean -f docker-compose-test-clean.yml rm -fv || true
