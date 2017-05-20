#!/usr/bin/env bash

export PACT_BROKER_BASIC_AUTH_USERNAME="foo"
export PACT_BROKER_BASIC_AUTH_PASSWORD="bar"
./script/test.sh
