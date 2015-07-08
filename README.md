Dockerised Pact Broker
==================

This repository deploys Pact Broker using lightweight containers using Docker.

## Prerequisites

* A running postgres database and the ability to connect to it

## Getting Started

1. [Install Docker](https://docs.docker.com/installation/)
2. Prepare your environment

  a. If running on OSX, run **fix_b2d_ports.sh** to forward the web port from the boot2docker vm.
    **You need to shutdown boot2docker before you run this script.**

  b. Setup the pact broker connection to the database through the use of the following environment variables
       * PACT_BROKER_DATABASE_USERNAME
       * PACT_BROKER_DATABASE_PASSWORD
       * PACT_BROKER_DATABASE_HOST
       * PACT_BROKER_DATABASE_NAME
3. Build the pact broker environment by executing **build.sh**
4. You're now ready to go!

## Notes

* On OSX, use `boot2docker ip` to get the IP of the VirtualBox, and connect on port 80.
* ~~On OSX you need to use 8080 due to boot2docker's virtual box generally not having the right priviliges to start a new process listing to default web port.~~ This doesn't seem to be true/true anymore.
* Currently, the application makes use of thin, but you can update the Gemfile to use any application server you like.
* As the native dependencies for a postgres driver are baked into the docker container, you are limited to using postgres as a database.
* Apart from creating a postgres database no futher prepartion is required.


## Publishing to Docker Hub

1. Login to docker hub from console

```
docker login
```

This will prompt for your docker hub credentials and email

2. Build the docker image for the dius account

```
docker build -t=dius/pact_broker .
```

3. Publish to docker hub (dius organisation)

```
docker push dius/pact_broker:0.0.1
```
