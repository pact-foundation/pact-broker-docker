#!/bin/sh

set -euo

docker tag pactfoundation/pact-broker:latest pactfoundation/pact-broker:${TAG}
docker tag pactfoundation/pact-broker:latest pactfoundation/pact-broker:${MAJOR_TAG}
docker push pactfoundation/pact-broker:latest
docker push pactfoundation/pact-broker:${TAG}
docker push pactfoundation/pact-broker:${MAJOR_TAG}
