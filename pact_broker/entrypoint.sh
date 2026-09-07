#!/bin/sh

# Send a lightweight, anonymous analytics ping (version + platform) to help us
# understand adoption of this image. Opt out with PACT_DO_NOT_TRACK or
# SCARF_NO_ANALYTICS. See https://docs.pact.io/telemetry for details.
if [ -z "${PACT_DO_NOT_TRACK:-}" ] && [ -z "${SCARF_NO_ANALYTICS:-}" ] &&
  [ -n "${PACT_BROKER_DOCKER_VERSION:-}" ] && [ -n "${PACT_BROKER_DOCKER_PLATFORM:-}" ]; then
  wget -q -T 2 -t 1 -O /dev/null "https://d.pactflow.io/pact-broker-docker/${PACT_BROKER_DOCKER_VERSION}/${PACT_BROKER_DOCKER_PLATFORM}" >/dev/null 2>&1 &
fi

# PID 1 is this shell, so signals must be forwarded by hand or `docker stop`
# never reaches Puma and every shutdown ends in SIGKILL. Installed before either
# child starts, so a signal arriving during startup is forwarded rather than
# killing the shell and orphaning them.
forward_term() {
  if [ -n "${scheduler_pid:-}" ]; then
    kill -TERM "${scheduler_pid}" 2>/dev/null || true
  fi
  if [ -n "${puma_pid:-}" ]; then
    kill -TERM "${puma_pid}" 2>/dev/null || true
  fi
}
trap forward_term TERM INT

if [ "${PACT_BROKER_DATABASE_CLEAN_ENABLED}" = "true" ]; then
  bundle exec ruby /pact_broker/script/clean-scheduler.rb &
  scheduler_pid=$!
fi

bundle exec puma &
puma_pid=$!

wait "${puma_pid}"
# `wait` returns as soon as the trap fires, so wait again for the real exit.
wait "${puma_pid}"
