#!/bin/sh

set -euo

docker tag dius/pact-broker:latest dius/pact-broker:${TAG}
docker tag dius/pact-broker:latest dius/pact-broker:${MAJOR_TAG}
docker push dius/pact-broker:latest
docker push dius/pact-broker:${TAG}
docker push dius/pact-broker:${MAJOR_TAG}
