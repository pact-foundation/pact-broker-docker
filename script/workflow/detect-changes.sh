#!/bin/sh

if [ -z "$(git diff pact_broker/Gemfile.lock)" ] ; then
  echo "No gems updated. Exiting."
  exit 1
else
  echo "Gems updated, continuing with release."
fi
