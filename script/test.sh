#!/usr/bin/env bash

# This script
# - builds pact_broker image from docker file
# - connects to the application to check it works
# - works in Linux, TravisCI and OSX

# Exit immediately if a command exits with a non-zero status
set -e

# Commented out as it eats stderr and `set -e` should suffice
#  trap 'echo "FAILED"; exit 1' ERR

# echo fn that outputs to stderr http://stackoverflow.com/a/2990533/511069
echoerr() {
  cat <<< "$@" 1>&2;
}

# print error and exit
die () {
  echoerr "ERROR: $0: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

# print error and exit
required_args () {
  echoerr ""
  echoerr "A postgres database on your host machine is required through below"
  echoerr "environment variables. Read POSTGRESQL.md for instructions."
  echoerr ""
  echoerr "Set below environment variables with appropriate values for your database:"
  echoerr "  export PACT_BROKER_DATABASE_USERNAME=pact_broker"
  echoerr "  export PACT_BROKER_DATABASE_PASSWORD=pact_broker"
  echoerr "  export PACT_BROKER_DATABASE_NAME=pact_broker"
  echoerr "  export PACT_BROKER_DATABASE_HOST=192.168.0.XXX"
  echoerr ""
  echoerr "And ensure you have allowed external connections."
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

# show docker logs if any then die
report_postgres_failed () {
  docker logs ${PSQL_CONT_NAME} || true
  die "Postgres failed to start"
}

if [ "${TRAVIS}" == "true" ]; then
  DISPOSABLE_PSQL=true
fi

# defaults
[ -z "${PACT_BROKER_PORT}" ]             && PACT_BROKER_PORT=9292
[ -z "${PSQL_WAIT_TIMEOUT}" ]            && PSQL_WAIT_TIMEOUT="10s"
[ -z "${PACT_WAIT_TIMEOUT}" ]            && PACT_WAIT_TIMEOUT="15s"
[ -z "${PACT_CONT_NAME}" ]               && PACT_CONT_NAME="broker-app"
[ -z "${PSQL_CONT_NAME}" ]               && PSQL_CONT_NAME="postgres"
[ -z "${PACT_BROKER_DATABASE_ADAPTER}" ] && PACT_BROKER_DATABASE_ADAPTER="postgres"
[ -z "${PACT_BROKER_PUBLIC_HEARTBEAT}" ] && PACT_BROKER_PUBLIC_HEARTBEAT="true"
[ -z "${PACT_BROKER_PUBLIC_HEARTBEAT}" ] && PACT_BROKER_PUBLIC_HEARTBEAT="true"
[ -z "${PACT_BROKER_WEBHOOK_HTTP_METHOD_WHITELIST}" ] && PACT_BROKER_WEBHOOK_HTTP_METHOD_WHITELIST="GET POST"
[ -z "${PACT_BROKER_WEBHOOK_SCHEME_WHITELIST}" ] && PACT_BROKER_WEBHOOK_SCHEME_WHITELIST="http https"
[ -z "${PACT_BROKER_WEBHOOK_HOST_WHITELIST}" ] && PACT_BROKER_WEBHOOK_HOST_WHITELIST="/.*\\.foo\\.com$/ bar.com 10.2.3.41/24"

# TODO clean up built containers
docker-compose -f docker-compose-rspec.yml up --build

echo "Will build the pact broker"
docker build -t=dius/pact_broker .

# Stop and remove any running broker-app container instances before updating
if docker ps -a | grep ${PACT_CONT_NAME}; then
  echo ""
  echo "Stopping and removing running instance of pact broker container"
  docker stop ${PACT_CONT_NAME}
  docker rm ${PACT_CONT_NAME}
fi

if [ "$(uname)" == "Darwin" ]; then
  PORT_BIND="${PACT_BROKER_PORT}:${PACT_BROKER_PORT}"
  if [ "true" == "$(command -v boot2docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
    TEST_IP=$(boot2docker ip)
  else
    if  [ "true" == "$(command -v docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
      TEST_IP='localhost'
    else
      if [ "true" == "$(command -v docker-machine > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
        TEST_IP=$(docker-machine ip default)
      else
        echo "Cannot detect either boot2docker, docker-machine, or docker native" && exit 1
    fi
  fi
fi
else
  PORT_BIND="${PACT_BROKER_PORT}"
fi

if [ "${DISPOSABLE_PSQL}" == "true" ]; then
  [ "$(uname)" == "Darwin" ] && die \
    "Running the disposable postgres is only supported in Linux for now."

  if docker ps -a | grep ${PSQL_CONT_NAME}; then
    echo ""
    echo "Stopping and removing running instance of postgres container"
    docker stop ${PSQL_CONT_NAME}
    docker rm ${PSQL_CONT_NAME}
  fi

  PACT_BROKER_DATABASE_USERNAME=postgres
  PACT_BROKER_DATABASE_NAME=pact
  PGUSER=${PACT_BROKER_DATABASE_USERNAME}
  PGDATABASE=${PACT_BROKER_DATABASE_NAME}
  if pwgen -n1 >/dev/null 2>&1; then
    PGPASSWORD=$(pwgen -c -n -1 $(echo $[ 7 + $[ RANDOM % 17 ]]) 1)
  else
    PGPASSWORD="no_pwdgen_so_hardcoded_password"
  fi
  PACT_BROKER_DATABASE_PASSWORD=$PGPASSWORD

  # Run psql
  PSQL_IMG=postgres:9.4.5
  docker pull ${PSQL_IMG}

  echo ""
  echo "Run the docker postgres image '${PSQL_IMG}'"
  # Using `--privileged` due to
  #  pg_ctl: could not send stop signal (PID: 55): Permission denied
  #  in TravisCI
  docker run --privileged -d --name=${PSQL_CONT_NAME} -p 5432 \
    -e POSTGRES_PASSWORD=${PGPASSWORD} \
    -e PGPASSWORD \
    -e PGUSER \
    -e PGPORT="5432" \
    ${PSQL_IMG}
  sleep 1 && docker logs ${PSQL_CONT_NAME}

  timeout --foreground ${PSQL_WAIT_TIMEOUT} \
    $(dirname "$0")/wait_psql.sh ${PSQL_CONT_NAME} || report_postgres_failed

  PACT_BROKER_DATABASE_HOST=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${PSQL_CONT_NAME}`
  echo "Postgres container IP is: ${PACT_BROKER_DATABASE_HOST}"

  echo ""
  echo "Create the pact database '${PGDATABASE}'"
  docker exec -ti ${PSQL_CONT_NAME} sh -c \
    "PGPASSWORD=${PGPASSWORD} psql -U ${PGUSER} -c 'CREATE DATABASE ${PGDATABASE};'"
  docker exec -ti ${PSQL_CONT_NAME} sh -c \
    "PGPASSWORD=${PGPASSWORD} psql -U ${PGUSER} -c '\connect ${PGDATABASE}'"
fi

# Validate required variables
[ -z "${PACT_BROKER_DATABASE_NAME}" ] && required_args

echo ""
echo "Run the built Pact Broker"
# Using `--privileged` due to unspecified issues in TravisCI
docker run --privileged --name=${PACT_CONT_NAME} -d -p ${PORT_BIND} \
  -e PACT_BROKER_DATABASE_ADAPTER=${PACT_BROKER_DATABASE_ADAPTER} \
  -e PACT_BROKER_DATABASE_USERNAME=${PACT_BROKER_DATABASE_USERNAME} \
  -e PACT_BROKER_DATABASE_PASSWORD=${PACT_BROKER_DATABASE_PASSWORD} \
  -e PACT_BROKER_DATABASE_HOST=${PACT_BROKER_DATABASE_HOST} \
  -e PACT_BROKER_DATABASE_NAME=${PACT_BROKER_DATABASE_NAME} \
  -e PACT_BROKER_DATABASE_PORT=${PACT_BROKER_DATABASE_PORT} \
  -e PACT_BROKER_BASIC_AUTH_USERNAME=${PACT_BROKER_BASIC_AUTH_USERNAME} \
  -e PACT_BROKER_BASIC_AUTH_PASSWORD=${PACT_BROKER_BASIC_AUTH_PASSWORD} \
  -e PACT_BROKER_PUBLIC_HEARTBEAT=${PACT_BROKER_PUBLIC_HEARTBEAT} \
  -e PACT_BROKER_WEBHOOK_HTTP_METHOD_WHITELIST="${PACT_BROKER_WEBHOOK_HTTP_METHOD_WHITELIST}" \
  -e PACT_BROKER_WEBHOOK_SCHEME_WHITELIST="${PACT_BROKER_WEBHOOK_SCHEME_WHITELIST}" \
  -e PACT_BROKER_WEBHOOK_HOST_WHITELIST="${PACT_BROKER_WEBHOOK_HOST_WHITELIST}" \
  -e PACT_BROKER_LOG_LEVEL=INFO \
  dius/pact_broker
sleep 1 && docker logs ${PACT_CONT_NAME}

echo ""
echo "Checking that the Pact Broker container is still up and running"
docker inspect -f "{{ .State.Running }}" ${PACT_CONT_NAME} | grep true || die \
  "The Pact Broker container is not running!"

if [ -z "${TEST_IP}" ]; then
  TEST_IP=`docker inspect -f='{{ .NetworkSettings.IPAddress }}' ${PACT_CONT_NAME}`
fi
TEST_URL="http://${TEST_IP}:${PACT_BROKER_PORT}"
echo "TEST_URL is '${TEST_URL}'"

echo ""
echo "Checking that server can be connected from outside the Docker container"
PACT_BROKER_HOST=${TEST_IP} $(dirname "$0")/wait_pact.sh ${PACT_WAIT_TIMEOUT} ${PACT_BROKER_BASIC_AUTH_USERNAME} ${PACT_BROKER_BASIC_AUTH_PASSWORD}

echo ""
echo "Checking that server accepts and return HTML from outside"
curl -H "Accept:text/html" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} -s "${TEST_URL}"

echo ""
echo "Checking for specific HTML content from outside: 'Pacts'"
curl -H "Accept:text/html" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} -s "${TEST_URL}" | grep "Pacts"

echo "Checking that server accepts and responds with status 200"
response_code=$(curl -s -o /dev/null -w "%{http_code}" --user ${PACT_BROKER_BASIC_AUTH_USERNAME}:${PACT_BROKER_BASIC_AUTH_PASSWORD} ${TEST_URL})

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

if [[ ! -z "${PACT_BROKER_BASIC_AUTH_USERNAME}" ]]; then
  echo ""
  echo "Checking that basic auth is configured"
  response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL})

  if [[ "${response_code}" -ne '401' ]]; then
    die "Expected response code to be 401, but was ${response_code}"
  fi
fi

script/publish.sh "${TEST_URL}"

echo ""
echo "Checking that badges can be accessed without basic auth"
response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL}/pacts/provider/Bar/consumer/Foo/latest/badge.svg)

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

echo "Checking that the heartbeat URL can be accessed without basic auth"
response_code=$(curl -s -o /dev/null -w "%{http_code}" ${TEST_URL}/diagnostic/status/heartbeat)

if [[ "${response_code}" -ne '200' ]]; then
  die "Expected response code to be 200, but was ${response_code}"
fi

echo "SUCCESS: All tests passed!"
