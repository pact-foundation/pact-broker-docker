Dockerised Pact Broker [![Build Status](https://travis-ci.org/pact-foundation/pact-broker-docker.svg)](https://travis-ci.org/pact-foundation/pact-broker-docker)
==================

This repository contains a Dockerized version of the [Pact Broker][pact-broker]. You can pull the `pactfoundation/pact-broker` image from [Dockerhub][pact-broker-docker]. If you're viewing these docs on Dockerhub, here is a link to the [github repository][github].

## In a hurry?

If you want to try out a Pact Broker that can be accessed by all your teams, without having to fill in requisition forms and wait for 3 months, you can get a free trial at <a href="https://pactflow.io/?utm_source=github&utm_campaign=pact_foundation_pact_broker_docker"/>pactflow.io</a>. Built by a group of core Pact maintainers, Pactflow is a fork of the OSS Pact Broker with extra goodies like an improved UI, field level verification results and federated login. It's also fully supported, and that means when something goes wrong, *someone else* gets woken up in the middle of the afternoon to fix it...

## Notes migration from dius/pact-broker image

The `pactfoundation/pact-broker` image is a forked version of the `dius/pact-broker` image. It is smaller (as it runs on Alpine Linux with Puma instead of the larger Passenger Phusion base image), and does not need root permissions.

All the environment variables used for `dius/pact-broker` are compatible with `pactfoundation/pact-broker`. The only breaking change is that the default port has changed from `80` to `9292` (because a user without root permisisons cannot bind to a port under 1024). If you wish to expose port 80 (or 443) you can deploy Ngnix in front of it (see the [docker-compose](https://github.com/pact-foundation/pact-broker-docker/blob/master/docker-compose.yml) file for an example).

### Which one should I use?

Please read https://github.com/phusion/passenger/wiki/Puma-vs-Phusion-Passenger for information on which server will suit your needs best. The tl;dr is that if you want to run the docker image in a managed architecture which will make your application highly available (eg. ECS, Kubernetes) then use the `pactfoundation/pact-broker`. Puma will not restart itself if it crashes, so you will need external monitoring to ensure the Pact Broker stays available.

If you want to run the container as a standalone instance, then the `dius/pact-broker` image which uses Phusion Passenger may serve you better, as Passenger will restart any crashed processes.

## Prerequisites

* A running postgresql database and the ability to connect to it (see [POSTGRESQL.md][postgres]).
* If on Mac, you will need the `timeout` or `gtimeout` function. You can install `gtimeout` using `brew install coreutils`.

## Getting Started

1. [Install Docker][docker]
2. Prepare your environment if you are not running postgresql in a docker container. Setup the pact broker connection to the database through the use of the following environment variables. If you want to use a disposable postgres docker container just do `export DISPOSABLE_PSQL=true` before running the [script/test.sh][test-script].

For a postgres or mysql database:

    * PACT_BROKER_DATABASE_ADAPTER (optional, defaults to 'postgres', see note below.)
    * PACT_BROKER_DATABASE_USERNAME
    * PACT_BROKER_DATABASE_PASSWORD
    * PACT_BROKER_DATABASE_HOST
    * PACT_BROKER_DATABASE_PORT (optional, defaults to the default port for the specified adapter)
    * PACT_BROKER_DATABASE_NAME

Adapter can be 'postgres' (recommended) or 'mysql2' (please note that future JSON search features may not be supported on mysql).

For an sqlite database (only recommended for investigation/spikes, as it will be disposed of with the container unless you mount it from an external file system):

  * PACT_BROKER_DATABASE_ADAPTER (set to 'sqlite')
  * PACT_BROKER_DATABASE_NAME (arbitrary name eg. pact_broker.sqlite)

3. Test the pact broker environment by executing [script/test.sh][test-script]

## Notes

* On OSX, if you are not using Docker native, use `docker-machine ip $(docker-machine active)` to get the IP of the VirtualBox, and connect on port 9292.
* The application makes use of the Puma application server.
* Apart from creating a database no further preparation is required.

## Using basic auth

To enable basic auth, run your container with:

* `PACT_BROKER_BASIC_AUTH_USERNAME`
* `PACT_BROKER_BASIC_AUTH_PASSWORD`
* `PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME`
* `PACT_BROKER_BASIC_AUTH_READ_ONLY_PASSWORD`

If you want to allow public read access (but still require credentials for writing), then omit setting the READ_ONLY credentials and set `PACT_BROKER_ALLOW_PUBLIC_READ=true`.

Developers should use the read only credentials on their local machines, and the CI should use the read/write credentials. This will ensure that pacts and verification results are only published from your CI.

Note that the [verification status badges][badges] are not protected by basic auth, so that you may embed them in README markdown.

## Heartbeat URL

If you are using the docker container within an AWS autoscaling group, and you need to make a heartbeat URL publicly available, set `PACT_BROKER_PUBLIC_HEARTBEAT=true`. No database connection will be made during the execution of this endpoint.

The heartbeat is available at `/diagnostic/status/heartbeat`.

## Using SSL

See the [Pact Broker configuration documentation][reverse-proxy].

## Setting the log level

Set the environment variable `PACT_BROKER_LOG_LEVEL` to one of `DEBUG`, `INFO`, `WARN`, `ERROR`, or `FATAL`.

## Webhook whitelists

* PACT_BROKER_WEBHOOK_HOST_WHITELIST - a space delimited list of hosts (eg. `github.com`), network ranges (eg. `10.2.3.41/24`, or regular expressions (eg. `/.*\\.foo\\.com$/`). Regular expressions should start and end with a `/` to differentiate them from Strings. Note that backslashes need to be escaped with a second backslash. Please read the [Webhook whitelists][webhook-whitelist] section of the Pact Broker configuration documentation to understand how the whitelist is used. Remember to use quotes around this value as it may have spaces in it.
* PACT_BROKER_WEBHOOK_SCHEME_WHITELIST - a space delimited list (eg. `http https`). Defaults to `https`.

## Other environment variables

* PACT_BROKER_PORT - the port that the Pact Broker application runs on. Defaults to 9292.
* PACT_BROKER_DISABLE_SSL_VERIFICATION - `false` by default, may be set to `true`.
* PACT_BROKER_BASE_EQUALITY_ONLY_ON_CONTENT_THAT_AFFECTS_VERIFICATION_RESULTS - `true` by default, may be set to `false`.
* PACT_BROKER_ORDER_VERSIONS_BY_DATE - `true` by default. Setting this to false is deprecated.

## General Pact Broker configuration and usage

Documentation for the Pact Broker application itself can be found in the Pact Broker [wiki][pact-broker-wiki].

## Running with Docker Compose

For a quick start with the Pact Broker and Postgres, we have an example
[Docker Compose][docker-compose] setup you can use:

1. Modify the `docker-compose.yml` file as required.
2. Run `docker-compose build` to build the pact_broker container locally.
3. Run `docker-compose up` to get a running Pact Broker and a clean Postgres database.

Now you can access your local broker:

```sh
curl -v http://localhost # you can visit in your browser too!

# SSL endpoint, note that URLs in response contain https:// protocol
curl -v -k https://localhost:8443
```

_NOTE: this image should be modified before using in Production, in particular, the use of hard-coded credentials_

## Running with Openshift

See [pact-broker-openshift][pact-broker-openshift] for an example config file.

# Troubleshooting

See the [Troubleshooting][troubleshooting] page on the wiki.

[docker]: https://docs.docker.com/install/
[pact-broker]: https://github.com/pact-foundation/pact_broker
[pact-broker-docker]: https://hub.docker.com/r/pactfoundation/pact-broker/
[pact-broker-openshift]: https://github.com/jaimeniswonger/pact-broker-openshift
[badges]: https://github.com/pact-foundation/pact_broker/wiki/Provider-verification-badges
[troubleshooting]: https://github.com/pact-foundation/pact-broker-docker/wiki/Troubleshooting
[postgres]: https://github.com/pact-foundation/pact-broker-docker/blob/master/POSTGRESQL.md
[test-script]: https://github.com/pact-foundation/pact-broker-docker/blob/master/script/test.sh
[docker-compose]: https://github.com/pact-foundation/pact-broker-docker/blob/master/docker-compose.yml
[pact-broker-wiki]: https://github.com/pact-foundation/pact_broker/wiki
[reverse-proxy]: https://github.com/pact-foundation/pact_broker/wiki/Configuration#running-the-broker-behind-a-reverse-proxy
[webhook-whitelist]: https://github.com/pact-foundation/pact_broker/wiki/Configuration#webhook-whitelists
[github]: https://github.com/pact-foundation/pact-broker-docker
