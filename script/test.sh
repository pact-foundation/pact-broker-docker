#!/bin/sh

set -e

: "${TAG:?TAG must be provided}"

docker_compose_files=$(find . -name "docker-compose-test*.yml")

for file in $docker_compose_files; do
  cat $file | sed -e "s/pactfoundation\/pact-broker:latest.*/pactfoundation\/pact-broker:${TAG}\"/g" > dc-tmp
  mv dc-tmp $file
done

cleanup() {
  docker-compose -f docker-compose-tests.yml rm -fv  || true
  docker-compose -f docker-compose-test-different-env-var-names.yml rm -fv || true
}
trap cleanup EXIT

cleanup

docker-compose -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
cleanup

export PACT_BROKER_BASIC_AUTH_USERNAME=foo
export PACT_BROKER_BASIC_AUTH_PASSWORD=bar
export PACT_BROKER_PUBLIC_HEARTBEAT=true
docker-compose -f docker-compose-tests.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans

unset PACT_BROKER_BASIC_AUTH_USERNAME
unset PACT_BROKER_BASIC_AUTH_PASSWORD
unset PACT_BROKER_PUBLIC_HEARTBEAT

docker-compose -f docker-compose-test-different-env-var-names.yml up --build --abort-on-container-exit --exit-code-from sut --remove-orphans
