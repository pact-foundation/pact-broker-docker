# Dockerised Pact Broker

[![Build Status](https://travis-ci.org/pact-foundation/pact-broker-docker.svg?branch=master)](https://travis-ci.org/pact-foundation/pact-broker-docker)

This repository contains a Dockerized version of the [Pact Broker][pact-broker]. You can pull the `pactfoundation/pact-broker` image from [Dockerhub][pact-broker-docker]. If you're viewing these docs on Dockerhub, here is a link to the [github repository][github].

> Note: On 12 May 2018, the format of the docker tag changed from `M.m.p-RELEASE` to `M.m.p.RELEASE` (where `M.m.p` is the semantic version of the underlying Pact Broker package) so that Dependabot can recognise when the version has been incremented.

## In a hurry?

If you want to try out a Pact Broker that can be accessed by all your teams, without having to fill in requisition forms and wait for 3 months, you can get a free trial at <a href="https://pactflow.io/?utm_source=github&utm_campaign=pact_foundation_pact_broker_docker">pactflow.io</a>. Built by a group of core Pact maintainers, Pactflow is a fork of the OSS Pact Broker with extra goodies like an improved UI, field level verification results and federated login. It's also fully supported, and that means when something goes wrong, *someone else* gets woken up in the middle of the afternoon to fix it...

## Migrating from the dius/pact-broker image

The `pactfoundation/pact-broker` image is a forked version of the `dius/pact-broker` image. It is smaller (as it runs on Alpine Linux with Puma instead of the larger Passenger Phusion base image), and does not need root permissions.

All the environment variables used for `dius/pact-broker` are compatible with `pactfoundation/pact-broker`. The only breaking change is that the default port has changed from `80` to `9292` (because a user without root permisisons cannot bind to a port under 1024). If you wish to expose port 80 (or 443) you can deploy Ngnix in front of it (see the [docker-compose](https://github.com/pact-foundation/pact-broker-docker/blob/master/docker-compose.yml) file for an example).

### Which one should I use?

Please read https://github.com/phusion/passenger/wiki/Puma-vs-Phusion-Passenger for information on which server will suit your needs best. The tl;dr is that if you want to run the docker image in a managed architecture which will make your application highly available (eg. ECS, Kubernetes) then use the `pactfoundation/pact-broker`. Puma will not restart itself if it crashes, so you will need external monitoring to ensure the Pact Broker stays available.

If you want to run the container as a standalone instance, then the `dius/pact-broker` image which uses Phusion Passenger may serve you better, as Passenger will restart any crashed processes.

## Prerequisites

* A running Postgresql (or MySQL) database and the ability to connect to it (see [POSTGRESQL.md][postgres]). Postgres is recommended over MySQL for performance and support reasons.

## Getting Started

1. [Install Docker][docker]
2. Prepare your environment if you are not running postgresql in a docker container. Setup the pact broker connection to the database through the use of the following environment variables.

### Create the database

On an instance of Postgres version 10 or later, connect as a user with administrator privileges and run:

```
CREATE DATABASE pact_broker;
CREATE ROLE pact_broker WITH LOGIN PASSWORD 'CHANGE_ME';
GRANT ALL PRIVILEGES ON DATABASE pact_broker TO pact_broker;
```

### Configure the connection details

You can either set the `PACT_BROKER_DATABASE_URL` in the format `driver://username:password@host:port/database` (eg. `postgres://user1:pass1@myhost/mydb`) or, you can set the credentials individually using the following environment variables:

    * `PACT_BROKER_DATABASE_ADAPTER` (optional, defaults to 'postgres', see note below.)
    * `PACT_BROKER_DATABASE_USERNAME`
    * `PACT_BROKER_DATABASE_PASSWORD`
    * `PACT_BROKER_DATABASE_HOST`
    * `PACT_BROKER_DATABASE_NAME`
    * `PACT_BROKER_DATABASE_PORT` (optional, defaults to the default port for the specified adapter)

Adapter can be 'postgres' (recommended) or 'sqlite' (non production use only).

For investigations/spikes you can use SQlite. It is not supported as a production database, as it does not support concurrent requests. Additionally, unless you mount it from an external volume, the database will be disposed of when the container shuts down.

  * `PACT_BROKER_DATABASE_ADAPTER` (set to `sqlite`)
  * `PACT_BROKER_DATABASE_NAME` (arbitrary file in the `/tmp` directory eg. `/tmp/pact_broker.sqlite3`)

You can additionally set:

    * `PACT_BROKER_DATABASE_SSLMODE` - optional, possible values: 'disable', 'allow', 'prefer', 'require', 'verify-ca', or 'verify-full' to choose how to treat SSL (only respected if using the postgres database adapter. See https://www.postgresql.org/docs/9.1/libpq-ssl.html for more information.)
    * `PACT_BROKER_SQL_LOG_LEVEL` - optional, defaults to debug. The level at which to log SQL statements.
    * `PACT_BROKER_SQL_LOG_WARN_DURATION` - optional, defaults to 5 seconds. Log the SQL for queries that take longer than this number of seconds.
    * `PACT_BROKER_DATABASE_MAX_CONNECTIONS` - optional, defaults to 4. The maximum size of the connection pool. There is no need to set this unless you notice particular connection contention issues.
    * `PACT_BROKER_DATABASE_POOL_TIMEOUT` - optional, 5 seconds by default. The number of seconds to wait if a connection cannot be acquired before raising an error. There is no need to set this unless you notice particular connection contention issues.
    * `PACT_BROKER_DATABASE_CONNECT_MAX_RETRIES` - optional, defaults to 0. When running the Pact Broker Docker image experimentally using Docker Compose on a local development machine, the Broker application process may be ready before the database is available for connection, causing the application container to exit with an error. Setting the max retries to a non-zero number will allow it to retry the connection the configured number of times, waiting 3 seconds between attempts.

## Notes

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

## Webhooks

### Webhook whitelists

* `PACT_BROKER_WEBHOOK_HOST_WHITELIST` - a space delimited list of hosts (eg. `github.com travis.org`), network ranges (eg. `10.2.3.41/24`, or regular expressions (eg. `/.*\\.foo\\.com$/`). Regular expressions should start and end with a `/` to differentiate them from Strings. Note that backslashes need to be escaped with a second backslash. Please read the [Webhook whitelists][webhook-whitelist] section of the Pact Broker configuration documentation to understand how the whitelist is used. Remember to use quotes around this value as it may have spaces in it.
* `PACT_BROKER_WEBHOOK_SCHEME_WHITELIST` - a space delimited list (eg. `http https`). Defaults to `https`.

## Other webhook settings

* `PACT_BROKER_WEBHOOK_RETRY_SCHEDULE` - a space delimited list of integers specifying the number of seconds after which to retry webhook requests when they fail. Defaults to `10 60 120 300 600 1200`. This does not normally need to be changed.

## Other environment variables

* `PACT_BROKER_PORT` - the port that the Pact Broker application runs on. Defaults to 9292.
* `PACT_BROKER_BASE_URL` - optional but *strongly recommended* when deploying the Pact Broker to production as it prevents some [security vulnerabilities](https://www.cloudflare.com/learning/dns/dns-cache-poisoning/). If you find that the URLs generated by the API are using an IP instead of a hostname, you can set this environment variable to force the desired base URL. Must include the port if it's a non-standard one. eg. `https://my-broker:9292`. This can also be used if you are mounting the Docker container so that it runs on a non root context eg. `https://my-company.com/pact-broker`. Not that this setting does not change where the application is mounted within the Docker container - it just changes the links.
* `PACT_BROKER_DISABLE_SSL_VERIFICATION` - `false` by default, may be set to `true`.
* `PACT_BROKER_BASE_EQUALITY_ONLY_ON_CONTENT_THAT_AFFECTS_VERIFICATION_RESULTS` - `true` by default, may be set to `false`.
* `PACT_BROKER_ORDER_VERSIONS_BY_DATE` - `true` by default. Setting this to false is deprecated.
* `PACT_BROKER_PUMA_PERSISTENT_TIMEOUT` - allows configuration of the Puma persistent timeout.


## General Pact Broker configuration and usage

Documentation for the Pact Broker application itself can be found in the Pact Broker [docs][pact-broker-docs].

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

If you call your service "pact_broker", an environment variable called `PACT_BROKER_PORT` will be created which will conflict with the Docker image's `PACT_BROKER_PORT` (see this [issue](https://github.com/pact-foundation/pact-broker-docker/issues/7) for background). In this case, you have two options.

* Give your service a name that is *not* "pact_broker".
* [Use different environment variable names](#using-different-environment-variable-names)

See [pact-broker-openshift][pact-broker-openshift] for an example config file.

## Running on Kubernetes

If you call your service "pact_broker", an environment variable called `PACT_BROKER_PORT` will be created which will conflict with the Docker image's `PACT_BROKER_PORT` (see this [issue](https://github.com/pact-foundation/pact-broker-docker/issues/7) for background). In this case, you have two options.

* Give your service a name that is *not* "pact_broker".
* [Use different environment variable names](#using-different-environment-variable-names)

## Running on Heroku

Heroku provides the database connection string as the environment variable `DATABASE_URL`, and the port as `PORT`. See the section on [Using different environment variable names](#using-different-environment-variable-names) to allow the Pact Broker to use these environment variables instead of `PACT_BROKER_PORT` and `PACT_BROKER_DATABASE_URL`.

## Running on AWS with an ALB

If you are running the Docker image behind an ALB with an idle timeout, you may need to set the Puma persistent timeout using the `PACT_BROKER_PUMA_PERSISTENT_TIMEOUT` environment variable. See [issue 26](https://github.com/pact-foundation/pact-broker-docker/issues/26) for details.

You will also want to make use of the [Heartbeat URL](#heartbeat-url)

## Using different environment variable names

If you are running your Docker container in a managed environment, you may not be able to control the names of the environment variables that are set by that software.

In this case, you can tell the application to use different environment variables to source the following configuration options.

### Port

To allow the port of the Pact Broker to be set by a different environment variable, set `PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME` to the name of your chosen variable, and then set that variable. eg.

```sh
PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME=PACT_BROKER_APPLICATION_PORT
PACT_BROKER_APPLICATION_PORT=5000
```

### Database URL

To allow the URL of the database to be set by a different environment variable, set `PACT_BROKER_DATABASE_URL_ENVIRONMENT_VARIABLE_NAME` to the name of your chosen variable, and then set that variable. eg.

```
PACT_BROKER_DATABASE_URL_ENVIRONMENT_VARIABLE_NAME=DATABASE_URL
DATABASE_URL=...
```

## Database migrations

The Pact Broker auto migrates on startup, and will always do so in a way that is backwards compatible, to support architectures that run multiple instances of the application at a time (eg. AWS auto scaling).

You can use a custom entrypoint to the Pact Broker Docker image to perform a rollback. A rollback would be required if you needed to downgrade your Pact Broker image. The db-migrate entrypoint is support in versions 2.76.1.1 and later.
To perform the rollback, you must use at minimum the version of the Docker image that performed the migrations in the first place. You can always use the latest image to rollback.

To work out which migration to rollback to, select the tag of the Pact Broker gem version you want at https://github.com/pact-foundation/pact_broker and then look in the `db/migrations` directory. Find the very last migration in the directory, and take the numbers at the start of the file name. This is your "target".

```
# You can use the PACT_BROKER_DATABASE_URL or the separate environment variables as listed in the Getting Started section.

docker run --rm \
    -e PACT_BROKER_DATABASE_URL=<url> \
    -e PACT_BROKER_MIGRATION_TARGET=<target> \
    --entrypoint db-migrate \
    pactfoundation/pact-broker
```

To get the current version of the database run:

```
docker run --rm \
    -e PACT_BROKER_DATABASE_URL=<url> \
    --entrypoint db-version \
    pactfoundation/pact-broker
```

# Troubleshooting

See the [Troubleshooting][troubleshooting] page on the docs site.

[docker]: https://docs.docker.com/install/
[pact-broker]: https://github.com/pact-foundation/pact_broker
[pact-broker-docker]: https://hub.docker.com/r/pactfoundation/pact-broker/
[pact-broker-openshift]: https://github.com/jaimeniswonger/pact-broker-openshift
[badges]: https://docs.pact.io/pact_broker/advanced_topics/provider_verification_badges
[troubleshooting]: https://github.com/pact-foundation/pact-broker-docker/wiki/Troubleshooting
[postgres]: https://github.com/pact-foundation/pact-broker-docker/blob/master/POSTGRESQL.md
[test-script]: https://github.com/pact-foundation/pact-broker-docker/blob/master/script/test.sh
[docker-compose]: https://github.com/pact-foundation/pact-broker-docker/blob/master/docker-compose.yml
[pact-broker-docs]: https://docs.pact.io/pact_broker/
[reverse-proxy]: https://docs.pact.io/pact_broker/configuration#running-the-broker-behind-a-reverse-proxy
[webhook-whitelist]: https://docs.pact.io/pact_broker/configuration#webhook-whitelists
[github]: https://github.com/pact-foundation/pact-broker-docker
