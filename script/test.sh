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
[ -z "${PACT_BROKER_PORT}" ]  && PACT_BROKER_PORT=80
[ -z "${PSQL_WAIT_TIMEOUT}" ] && PSQL_WAIT_TIMEOUT="10s"
[ -z "${PACT_WAIT_TIMEOUT}" ] && PACT_WAIT_TIMEOUT="15s"
[ -z "${PACT_CONT_NAME}" ]    && PACT_CONT_NAME="broker_app"
[ -z "${PSQL_CONT_NAME}" ]    && PSQL_CONT_NAME="postgres"

echo "Will build the pact broker"
docker build -t=dius/pact_broker .

# Stop and remove any running broker_app container instances before updating
if docker ps -a | grep ${PACT_CONT_NAME}; then
  echo ""
  echo "Stopping and removing running instance of pact broker container"
  docker stop ${PACT_CONT_NAME}
  docker rm ${PACT_CONT_NAME}
fi

if [ "$(uname)" == "Darwin" ]; then
  PORT_BIND="${PACT_BROKER_PORT}:${PACT_BROKER_PORT}"
  EXTERN_BROKER_PORT=${PACT_BROKER_PORT}
  if [ "true" == "$(command -v boot2docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
    test_ip=$(boot2docker ip)
  else
    if [ "true" == "$(command -v docker-machine > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
      test_ip=$(docker-machine ip default)
    else
      if  [ "true" == "$(command -v docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
        test_ip='localhost'
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
[ -z "${PACT_BROKER_DATABASE_USERNAME}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_PASSWORD}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_HOST}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_NAME}" ] && required_args

echo ""
echo "Run the built Pact Broker"
# Using `--privileged` due to unspecified issues in TravisCI
docker run --privileged --name=${PACT_CONT_NAME} -d -p ${PORT_BIND} \
  -e PACT_BROKER_DATABASE_USERNAME=${PACT_BROKER_DATABASE_USERNAME} \
  -e PACT_BROKER_DATABASE_PASSWORD=${PACT_BROKER_DATABASE_PASSWORD} \
  -e PACT_BROKER_DATABASE_HOST=${PACT_BROKER_DATABASE_HOST} \
  -e PACT_BROKER_DATABASE_NAME=${PACT_BROKER_DATABASE_NAME} \
  -e PACT_BROKER_DATABASE_PORT=${PACT_BROKER_DATABASE_PORT} \
  dius/pact_broker
sleep 1 && docker logs ${PACT_CONT_NAME}

# If the port was dynamically allocated by docker then find it out
if [ -z "${EXTERN_BROKER_PORT}" ]; then
  QUERY="{{(index (index .NetworkSettings.Ports "${PACT_BROKER_PORT}/tcp") 0).HostPort}}"
  EXTERN_BROKER_PORT=`docker inspect -f='${QUERY}' ${PACT_CONT_NAME}`
fi

echo ""
echo "Checking that the Pact Broker container is still up and running"
docker inspect -f "{{ .State.Running }}" ${PACT_CONT_NAME} | grep true || die \
  "The Pact Broker container is not running!"

echo ""
echo "Checking that server can be connected from within the Docker container"
docker exec ${PACT_CONT_NAME} wait_ready ${PACT_WAIT_TIMEOUT} || die \
  "When running wait_ready inside the container!"

if [ -z "${test_ip}" ]; then
  test_ip=`docker inspect -f='{{ .NetworkSettings.IPAddress }}' ${PACT_CONT_NAME}`
fi

echo ""
echo "Checking that server can be connected from outside the Docker container"
export PACT_BROKER_HOST=${test_ip}
$(dirname "$0")/../container/usr/bin/wait_ready ${PACT_WAIT_TIMEOUT}

echo ""
echo "Checking that server accepts and return HTML from outside"
curl -H "Accept:text/html" -s "http://${test_ip}:${EXTERN_BROKER_PORT}/ui/relationships"

echo ""
echo "Checking for specific HTML content from outside: '0 pacts'"
curl -H "Accept:text/html" -s "http://${test_ip}:${EXTERN_BROKER_PORT}/ui/relationships" | grep "0 pacts"

echo ""
echo "Checking that server accepts and responds with status 200"
response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${test_ip}:${EXTERN_BROKER_PORT})

if [[ "${response_code}" == '200' ]]; then
  echo ""
  echo "SUCCESS: All tests passed!"
else
  die "While checking HTML response status 200"
fi
