# Releasing

## Updating the Pact Broker gems

    script/update.sh <OPTIONAL_PACT_BROKER_GEM_VERSION>

## Testing

    script/test.sh

## Debugging

    docker build -t pactfoundation/pact-broker:latest .
    docker-compose -f docker-compose-dev.yml up --build

## Releasing image to Docker Hub

    export GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES=<a github token with public repo scope>
    script/trigger-release.sh
