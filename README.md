# Dockerised Pact Broker

This repository contains a Dockerized version of the [Pact Broker][pact-broker]. You can pull the `pactfoundation/pact-broker` image from [Dockerhub][pact-broker-docker]. If you're viewing these docs on Dockerhub, here is a link to the [github repository][github].

> Note: On 3 May 2023, the format of the docker tag changed from starting with the Pact Broker gem version (`2.107.0.1`), to ending with the Pact Broker gem version (`2.107.1-pactbroker2.107.1`). Read about the new versioning scheme [here](#versioning).

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/pact-foundation/pact-msw-adapter/graphs/commit-activity)

[![Build and test](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/test.yml/badge.svg)](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/test.yml)
[![Audit](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/audit.yml/badge.svg)](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/audit.yml)
[![Release](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/release_image.yml/badge.svg)](https://github.com/pact-foundation/pact-broker-docker/actions/workflows/release_image.yml)

[![pulls](https://badgen.net/docker/pulls/pactfoundation/pact-broker?icon=docker&label=pulls)](https://hub.docker.com/r/pactfoundation/pact-broker)
[![stars](https://badgen.net/docker/stars/pactfoundation/pact-broker?icon=docker&label=stars)](https://hub.docker.com/r/pactfoundation/pact-broker)

[![size: amd64](https://badgen.net/docker/size/pactfoundation/pact-broker/latest-multi/amd64?icon=docker&label=size%3Aamd64)](https://hub.docker.com/r/pactfoundation/pact-broker)
[![size: arm64](https://badgen.net/docker/size/pactfoundation/pact-broker/latest-multi/arm64?icon=docker&label=size%3Aarm64)](https://hub.docker.com/r/pactfoundation/pact-broker)
[![size: arm](https://badgen.net/docker/size/pactfoundation/pact-broker/latest-multi/arm?icon=docker&label=size%3Aarm)](https://hub.docker.com/r/pactfoundation/pact-broker)

## In a hurry?

If you want to try out a Pact Broker that can be accessed by all your teams, without having to fill in requisition forms and wait for 3 months, you can get a free trial at <a href="https://pactflow.io/?utm_source=github&utm_campaign=pact_foundation_pact_broker_docker">pactflow.io</a>. Built by a group of core Pact maintainers, PactFlow is a fork of the OSS Pact Broker with extra goodies like an improved UI, user and team management, secrets, field level verification results and federated login. It's also fully supported, and that means when something goes wrong, *someone else* gets woken up in the middle of the afternoon to fix it...

## Migrating from the dius/pact-broker image

The `pactfoundation/pact-broker` image is a forked version of the `dius/pact-broker` image. It is smaller (as it runs on Alpine Linux with Puma instead of the larger Passenger Phusion base image), and does not need root permissions.

All the environment variables used for `dius/pact-broker` are compatible with `pactfoundation/pact-broker`. The only breaking change is that the default port has changed from `80` to `9292` (because a user without root permisisons cannot bind to a port under 1024). If you wish to expose port 80 (or 443) you can deploy Ngnix in front of it (see the [docker-compose](https://github.com/pact-foundation/pact-broker-docker/blob/master/docker-compose.yml) file for an example).

### Which one should I use?

Please read https://github.com/phusion/passenger/wiki/Puma-vs-Phusion-Passenger for information on which server will suit your needs best. The tl;dr is that if you want to run the docker image in a managed architecture which will make your application highly available (eg. ECS, Kubernetes) then use the `pactfoundation/pact-broker`. Puma will not restart itself if it crashes, so you will need external monitoring to ensure the Pact Broker stays available.

If you want to run the container as a standalone instance, then the `dius/pact-broker` image which uses Phusion Passenger may serve you better, as Passenger will restart any crashed processes.

## Platforms

### Single platform images

By default, vanilla tags, are built only for `amd64`

- `--platform=linux/amd64`

  ```sh
  docker run --rm -it --entrypoint /bin/sh pactfoundation/pact-broker:latest -c 'uname -sm'
  ```

### Multi-manifest image

Multi-platform images are available, by appending `-multi` to any release tag

- `--platform=linux/amd64`
- `--platform=linux/arm/v7`
- `--platform=linux/arm64`

  ```sh
  docker run --rm -it --entrypoint /bin/sh pactfoundation/pact-broker:latest-multi -c 'uname -sm'
  ```

## Prerequisites

* A running Postgresql database (v9.4 or later) and the ability to connect to it (see [POSTGRESQL.md][postgres]).

## Getting Started

1. [Install Docker][docker] with Docker Engine 20.10.0 or later. **NOTE: Docker 19 is no longer supported by Docker, and the Pact Broker image will not run on it as the base image requires 20.10.0 or later.**
2. Create a Postgres database (Postgres 9.6 or later).
2. Setup the Pact Broker connection to the database using the environment variables described below.

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

  * `PACT_BROKER_DATABASE_ADAPTER="sqlite"`
  * `PACT_BROKER_DATABASE_NAME="/tmp/pact_broker.sqlite3"` (arbitrary file a directory which is writeable by the application process, recommended to use `/tmp`)

    OR

  * `PACT_BROKER_DATABASE_URL="sqlite:////tmp/pact_broker.sqlte3"`

See the [database section](https://docs.pact.io/pact_broker/configuration/settings/#database) of the Pact Broker configuration docs for all the database configuration options available.

## Notes

* The application makes use of the Puma application server.
* Apart from creating a database no further preparation is required.
* The image does not need root privileges to run, however, the root filesystem (or at least, the /tmp directory) must be writeable for Puma to temporarily store files when processing large requests. See this [issue](https://github.com/pact-foundation/pact-js/issues/583#issuecomment-777728677).

## Authentication

The Pact Broker comes with 2 configurable basic auth users - one with read/write privileges, and one with read only privileges. The read only credentials should be distributed to the developers for use from development machines, and the read/write credentials should be used for CI/CD.

See the [Authentication and authorization](https://docs.pact.io/pact_broker/configuration/settings#authentication-and-authorization) section of the Pact Broker documentation for more details.

Note that the [verification status badges][badges] are not protected by basic auth, so that you may embed them in README markdown.

## Heartbeat/Healthcheck URL

The heartbeat is available at `/diagnostic/status/heartbeat`. No database connection will be made during the execution of this endpoint.

If you have enabled basic auth, and you are running the Pact Broker within an AWS autoscaling group or similar and you need to make a heartbeat URL publicly available, set `PACT_BROKER_PUBLIC_HEARTBEAT=true`. 

## Using SSL

See the [Pact Broker configuration documentation][reverse-proxy].

## Setting the log level

Set the environment variable `PACT_BROKER_LOG_LEVEL` to one of `DEBUG`, `INFO`, `WARN`, `ERROR`, or `FATAL`.

## Webhooks

See the [Webhooks](https://docs.pact.io/pact_broker/configuration/features#webhooks) section of the Pact Broker documentation. The only setting that you need to customize is the [`webhook_host_whitelist`](https://docs.pact.io/pact_broker/configuration/settings#webhook_host_whitelist).

## Other settings

See the [Pact Broker Configuration Settings](https://docs.pact.io/pact_broker/configuration/settings) page for a full list of available settings.

* `PACT_BROKER_PORT` - the port that the Pact Broker application runs on. Defaults to 9292.
* `PACT_BROKER_BASE_URL` - optional but *strongly recommended* when deploying the Pact Broker to production as it prevents some [security vulnerabilities](https://www.cloudflare.com/learning/dns/dns-cache-poisoning/). If you find that the URLs generated by the API are using an IP instead of a hostname, you can set this environment variable to force the desired base URL. Must include the port if it's a non-standard one. eg. `https://my-broker:9292`. This can also be used if you are mounting the Docker container so that it runs on a non root context eg. `https://my-company.com/pact-broker`. Not that this setting does not change where the application is mounted within the Docker container - it just changes the links.
* `PACT_BROKER_PUMA_PERSISTENT_TIMEOUT` - allows configuration of the Puma persistent timeout.

## General Pact Broker configuration and usage

Documentation for the Pact Broker application itself can be found in the Pact Broker [docs][pact-broker-docs].

## Automatic data clean up

Performance can degrade when too much data accumulates in the Pact Broker. To read about the automatic data clean up feature, please see the [Maintenance](https://docs.pact.io/pact_broker/administration/maintenance) page of the Pact Broker documentation. 

You will need version `2.79.1.1` or later of the pactfoundation/pact-broker Docker image for this feature.

### Running the clean task on a cron schedule within the application container

If you have exactly one Pact Broker container running at a time, you can configure cron on the container to run the clean up.

* `PACT_BROKER_DATABASE_CLEAN_ENABLED`: set to `true` to enable the clean. Default is `false`.
* `PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE`: set to a cron schedule that will run when your Broker is under the least operational load. Default is 2:15am - `15 2 * * *`
* `PACT_BROKER_DATABASE_CLEAN_DELETION_LIMIT`: The maximum number of records to delete at a time for each of the categories listed in the [Categories of removable data](https://docs.pact.io/pact_broker/administration/maintenance#categories-of-removable-data). Defaults to `500`.
* `PACT_BROKER_DATABASE_CLEAN_OVERWRITTEN_DATA_MAX_AGE`: The maximum number of days to keep "overwritten" data as described in the [Categories of removable data](https://docs.pact.io/pact_broker/administration/maintenance#categories-of-removable-data)
* `PACT_BROKER_DATABASE_CLEAN_KEEP_VERSION_SELECTORS`:  a JSON string containing a list of the "keep" selectors described in [Configuring the keep selectors](https://docs.pact.io/pact_broker/administration/maintenance#configuring-the-keep-selectors) e.g `[{"latest": true, "branch": true}, { "max_age": 90 }, { "deployed" : true }, { "released" : true }]` (remember to escape the quotes if necessary in your configuration files/console).
* `PACT_BROKER_DATABASE_CLEAN_DRY_RUN`: defaults to `false`. Set to `true` to see the output of what *would* have been deleted if the task had run. This is helpful when experimenting with or fine tuning the clean feature. As nothing is deleted when in dry-run mode, the same output will be printed in the logs each time the task runs.

### Running the clean task from an external source

If you are running more than one Pact Broker Docker container at a time for the same database, then you will end up with two clean up tasks fighting with each other to delete the data. In this situation, it is best to run the clean task from an external location at a regular interval. To do this, run an instance of the pact-broker docker image with the entrypoint `clean`, the same database connection credentials as the application, and the same environment variables described in the section above *except the PACT_BROKER_DATABASE_CLEAN_ENABLED and PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE* vars.

You can see a working example in the [docker-compose-clean.yml](./docker-compose-clean.yml) file. To run the example locally, run:

```
docker-compose -f docker-compose-clean.yml up pact-broker

# in another console
docker-compose -f docker-compose-clean.yml up clean
```

### Known issues with the data clean up task

* When the pact-broker docker container gets restarted because of an internal error, another supercronic (the application that runs the cron task in the background) process seems to get started each time, leading to multiple clean tasks running at once. This issue has been noticed in local testing, but we do not know if it is likely to be an issue under normal production use. Please raise an issue if you are observing it. The mitigation for this is to run the clean from an external source as documented above.

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

1. Please read the [docs](https://github.com/puma/puma/blob/master/docs/kubernetes.md) about running Puma on Kubernetes.

2. If you call your service "pact_broker", an environment variable called `PACT_BROKER_PORT` will be created which will conflict with the Docker image's `PACT_BROKER_PORT` (see this [issue](https://github.com/pact-foundation/pact-broker-docker/issues/7) for background). In this case, you have two options.

   * Give your service a name that is *not* "pact_broker".
   * [Use different environment variable names](#using-different-environment-variable-names)

## Running on Heroku

Heroku provides the database connection string as the environment variable `DATABASE_URL`, and the port as `PORT`. See the section on [Using different environment variable names](#using-different-environment-variable-names) to allow the Pact Broker to use these environment variables instead of `PACT_BROKER_PORT` and `PACT_BROKER_DATABASE_URL`.

## Running with a Helm Chart

There is a community supported project that provides a [Pact Broker Helm Chart](https://github.com/ChrisJBurns/pact-broker-chart). Please note that this is not an official Pact Foundation supported project at this stage.

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
# Vulnerability scanning

* We use bundler audit on the underlying Pact Broker [codebase](https://github.com/pact-foundation/pact_broker/blob/master/.github/workflows/test.yml)
* We use trivy in our [release workflow](https://github.com/pact-foundation/pact-broker-docker/blob/master/script/release-workflow/run.sh)
* We also use [Snyk](https://app.snyk.io/org/pact-foundation-owm/projects) 

# Versioning

The Docker image tag uses a semantic-like versioning scheme (Docker tags don't support the `+` symbol, so we cannot implement a strict semantic version). The format of the tag is `M.m.p-pactbroker<pact_broker_version>` eg. `2.109.0-pactbroker2.107.1`. The `M.m.p` (eg. `2.109.0`) is the semantic part of the tag number, while the `-pactbroker<pact_broker_version>` suffix is purely informational.

The major version will be bumped for:

  * Major increments of the Pact Broker gem
  * Major increments of the base image that contain backwards incompatible changes (eg. dropping support for Docker 19)
  * Any other backwards incompatible changes made for any reason (eg. environment variable mappings, entrypoints, tasks, supported auth)

The minor version will be bumped for:

  * Minor increments of the Pact Broker gem
  * Additional non-breaking functionality added to the Docker image

The patch version will be bumped for:

  * Patch increments of the Pact Broker gem
  * Other fixes to the Docker image

Until May 2023, the versioning scheme used the `M.m.p` from the Pact Broker gem, with an additional `RELEASE` number at the end (eg. `2.107.0.1`). This scheme was replace by the current scheme because it was unable to semantically convey changes made to the Docker image that were unrelated to a Pact Broker gem version change (eg. alpine upgrades).

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
