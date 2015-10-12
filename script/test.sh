#!/bin/bash
# Prereq - you have set up a postgres database on your host machine and have allowed external connections.
#          Read POSTGRESQL.md for instructions.
# Prereq - you have exported the following environment variables with appropriate values for your database.
# export PACT_BROKER_DATABASE_USERNAME=pact_broker
# export PACT_BROKER_DATABASE_PASSWORD=pact_broker
# export PACT_BROKER_DATABASE_NAME=pact_broker
# export PACT_BROKER_DATABASE_HOST=192.168.0.XXX

# Build pact_broker image from docker file and connect to the application
set -e

trap 'echo "FAILED"; exit 1' ERR

docker build -t=dius/pact_broker .

# Stop and remove any running broker_app container instances before updating
docker ps -a | grep broker_app && \
  echo "Stopping and removing running instance of pact broker container" && \
  docker stop broker_app && \
  docker rm broker_app

if [ "$(uname)" == "Darwin" ]; then
  if [ "true" == "$(command -v boot2docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
    test_ip=$(boot2docker ip)
  else
    if [ "true" == "$(command -v docker-machine > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
      test_ip=$(docker-machine ip default)
    else
      echo "Cannot detect either boot2docker or docker-machine" && exit 1
    fi
  fi
else
  test_ip='localhost'
fi

docker run --name broker_app \
  -e PACT_BROKER_DATABASE_USERNAME=$PACT_BROKER_DATABASE_USERNAME \
  -e PACT_BROKER_DATABASE_PASSWORD=$PACT_BROKER_DATABASE_PASSWORD \
  -e PACT_BROKER_DATABASE_HOST=$PACT_BROKER_DATABASE_HOST \
  -e PACT_BROKER_DATABASE_NAME=$PACT_BROKER_DATABASE_NAME \
  -d -p 80:80 dius/pact_broker

sleep 5

container_id=$(docker ps -f name=broker_app | tail -1 | awk '{print $1}')
echo 'Checking that server can be connected to from within Docker container'
docker exec ${container_id} curl -v http://localhost:80
echo 'Checking that server can be connected to from outside Docker container'
curl http://${test_ip}:80
echo ''
response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${test_ip}:80)

[[ "${response_code}" != '200' ]] && echo 'Error retrieving index from oustide Docker container' && exit 1
[[ "${response_code}" == '200' ]] && echo 'Successfully retrieved index from outside Docker container'
