#!/usr/bin/env bash

# This script
# - waits for a Postgres docker container to be ready

# Exit immediately if a command exits with a non-zero status
set -e

container_id=$1

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

# Validate equired variables
[ -z "${container_id}" ] && die "Needs container_id through the first argument"

echo "Waiting for Postgres to be ready..."
while ! docker exec -ti ${container_id} \
          pg_isready --host=localhost --port=5432; do
  echo -n '.'
  sleep 1
done
echo "Done $0"
