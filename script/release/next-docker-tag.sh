#!/bin/sh

set -e

. script/functions

gem_version=$(gem_version_from_gemfile_lock)

if [ -z "${VERSION}" ]; then
  export INCREMENT=
  export VERSION=$(bundle exec bump show-next ${INCREMENT:-minor})

else
fi
