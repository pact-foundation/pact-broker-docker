#!/bin/bash
# Build pact_broker image from docker file
docker build -t=pact_broker .

# Stop and remove any running broker_app container instances before updating
docker ps -a | grep broker_app && \
  echo "Stopping and removing running instance of pact broker container" && \
  docker stop broker_app && \
  docker rm broker_app

# Start the container.
# Due to boot2docker not being able to map to port 80 (priviliged port),
# use 8080 for app running on OSX
if [ "$(uname)" == "Darwin" ]; then
  docker run --name broker_app \
    -e PACT_BROKER_DATABASE_USERNAME=$PACT_BROKER_DATABASE_USERNAME \
    -e PACT_BROKER_DATABASE_PASSWORD=$PACT_BROKER_DATABASE_PASSWORD \
    -e PACT_BROKER_DATABASE_HOST=$PACT_BROKER_DATABASE_HOST \
    -e PACT_BROKER_DATABASE_NAME=$PACT_BROKER_DATABASE_NAME \
    -w /app \
    -d -p 8080:80 pact_broker
else
  docker run --name broker_app \
    -e PACT_BROKER_DATABASE_USERNAME=$PACT_BROKER_DATABASE_USERNAME \
    -e PACT_BROKER_DATABASE_PASSWORD=$PACT_BROKER_DATABASE_PASSWORD \
    -e PACT_BROKER_DATABASE_HOST=$PACT_BROKER_DATABASE_HOST \
    -e PACT_BROKER_DATABASE_NAME=$PACT_BROKER_DATABASE_NAME \
    -w /app \
    -d -p 80:80 pact_broker
fi
