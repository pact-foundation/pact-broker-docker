#!/bin/sh
# This is a templated script to be run by build server
stack=$1
env=$2

docker compose run --rm stackup-"$env" pact-broker-"$stack" up \
  -t infrastructure/"$stack"/template.yaml \
  -p infrastructure/"$stack"/envs/common.yaml \
  -p infrastructure/"$stack"/envs/"$env".yaml
