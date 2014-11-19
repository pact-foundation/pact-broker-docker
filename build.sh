#!/bin/bash
docker build -t=pact_broker_img .

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
