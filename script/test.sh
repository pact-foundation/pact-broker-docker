#!/bin/sh

set -e

: "${TAG:?TAG must be provided}"
. ./script/distro.sh

PACT_BROKER_IMAGE="pactfoundation/pact-broker:${TAG}${TAG_SUFFIX}"
export PACT_BROKER_IMAGE
echo "Testing ${PACT_BROKER_IMAGE}"

# Every compose file gets its own Compose project name. Without this they all
# default to their directory name, so Compose can reuse a still-running
# container (e.g. postgres) from a previous suite instead of starting fresh,
# leaking state between suites.
cleanup() {
  docker compose -p pact-broker-tests -f test/compose/postgres/compose.yml rm -fv || true
  docker compose -p pact-broker-env-var-names -f test/compose/env-var-names/compose.yml rm -fv || true
  docker compose -p pact-broker-clean -f test/compose/clean/compose.yml rm -fv || true
  docker compose -p pact-broker-sqlite -f test/compose/sqlite/compose.yml rm -fv || true
  docker compose -p pact-broker-shutdown -f test/compose/clean/compose.yml rm -fsv || true
}
trap cleanup EXIT

cleanup

docker compose -p pact-broker-tests -f test/compose/postgres/compose.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
cleanup

export PACT_BROKER_BASIC_AUTH_USERNAME=foo
export PACT_BROKER_BASIC_AUTH_PASSWORD=bar
export PACT_BROKER_PUBLIC_HEARTBEAT=true
docker compose -p pact-broker-tests -f test/compose/postgres/compose.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

unset PACT_BROKER_BASIC_AUTH_USERNAME
unset PACT_BROKER_BASIC_AUTH_PASSWORD
unset PACT_BROKER_PUBLIC_HEARTBEAT

docker compose -p pact-broker-env-var-names -f test/compose/env-var-names/compose.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

docker compose -p pact-broker-clean -f test/compose/clean/compose.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
docker compose -p pact-broker-clean -f test/compose/clean/compose.yml rm -fv || true

docker compose -p pact-broker-sqlite -f test/compose/sqlite/compose.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
docker compose -p pact-broker-sqlite -f test/compose/sqlite/compose.yml rm -fv || true

./script/test-shutdown.sh
