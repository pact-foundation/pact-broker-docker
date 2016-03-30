Dockerised Pact Broker [![Build Status](https://travis-ci.org/DiUS/pact_broker-docker.svg)](https://travis-ci.org/DiUS/pact_broker-docker)
==================

This repository deploys [Pact Broker](https://github.com/bethesque/pact_broker) using lightweight containers using Docker.

## Prerequisites

* A running postgresql database and the ability to connect to it (see [POSTGRESQL.md](POSTGRESQL.md)).
* If on Mac, you will need the `timeout` or `gtimeout` function. You can install `gtimeout` using `brew install coreutils`.

## Getting Started

1. [Install Docker](https://docs.docker.com/installation/)
2. Prepare your environment if you are not running postgresql in a docker container. Setup the pact broker connection to the database through the use of the following environment variables. If you want to use a disposable postgres docker container just do `export DISPOSABLE_PSQL=true` before running the [script/test.sh](script/test.sh).
    * PACT_BROKER_DATABASE_USERNAME
    * PACT_BROKER_DATABASE_PASSWORD
    * PACT_BROKER_DATABASE_HOST
    * PACT_BROKER_DATABASE_NAME
3. Test the pact broker environment by executing [script/test.sh](script/test.sh)

## Notes

* Use `-p 80:80` to start the docker image, as some of the Rack middleware gets confused by receiving requests for other ports and will return a 404 otherwise (port forwarding does not rewrite headers).
* On OSX, use `boot2docker ip` to get the IP of the VirtualBox, and connect on port 80.
* ~~On OSX you need to use 8080 due to boot2docker's virtual box generally not having the right privileges to start a new process listing to default web port.~~ This doesn't seem to be true/true anymore.
* The application makes use of the phusion passenger application server.
* As the native dependencies for a postgres driver are baked into the docker container, you are limited to using postgres as a database.
* Apart from creating a postgres database no further preparation is required.

## Publishing to Docker Hub

1. Login to docker hub from console

```
docker login
```

This will prompt for your docker hub credentials and email

2. Build the docker image for the dius account

```
docker login
./script/build_and_push.sh # Note: have not tested this yet
```
