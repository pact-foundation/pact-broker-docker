# Releasing

## Updating the Pact Broker gems

    script/update.sh <OPTIONAL_PACT_BROKER_GEM_VERSION>

## Testing

    script/test.sh

## Debugging

    docker build -t pactfoundation/pact-broker:latest .
    docker-compose -f docker-compose-dev.yml up --build

## Releasing image to Docker Hub

Execute `https://github.com/pact-foundation/pact-broker-docker/actions/workflows/release_image.yml`

NOTE: the automatic version calculation code is broken because docker hub no longer allows public API access. The code in `script/release/next-docker-tag.sh` needs to be updated to use the git tags instead. Set the custom_tag when releasing until this is fixed.
