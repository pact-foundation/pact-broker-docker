#!/bin/bash
# Build pact_broker image from docker file
docker build -t=pact_broker_img .

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
    -e DB_USERNAME=$BROKER_DB_USERNAME \
    -e DB_PASSWORD=$BROKER_DB_PASSWORD \
    -e DB_HOST=$BROKER_DB_HOST \
    -e DB_NAME=$BROKER_DB_NAME \
    -w /app \
    -d -p 8080:80 pact_broker_img
else
  docker run --name broker_app \
    -e DB_USERNAME=$BROKER_DB_USERNAME \
    -e DB_PASSWORD=$BROKER_DB_PASSWORD \
    -e DB_HOST=$BROKER_DB_HOST \
    -e DB_NAME=$BROKER_DB_NAME \
    -w /app \
    -d -p 80:80 pact_broker_img
fi
