# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

ARG DISTRO=alpine

# MARK: Alpine
#
# gcompat is a musl compatibility shim. nokogiri needs it on arm and arm64,
# where the network graph breaks without it
# (https://github.com/sparklemotion/nokogiri/issues/2414). It is installed on
# every architecture so the build has no architecture-conditional branch.
#
# tzdata supplies the zoneinfo database. Alpine ships none, and the clean
# scheduler's `require "fugit"` fails outright without it.
FROM ruby:3.4.10-alpine3.24@sha256:c5a5064d190055633011c03aa800170cc36945ff3afb5f6c915329f92d6f1e00 AS runtime-alpine
RUN /bin/sh <<'EOT'
set -eu
apk upgrade --no-cache
apk add --no-cache gcompat libpq sqlite-libs tzdata yaml
adduser -h /pact_broker -s /bin/false -D -S -G root ruby
chmod g+w /pact_broker
EOT

FROM runtime-alpine AS build-alpine
RUN /bin/sh <<'EOT'
set -eu
apk add --no-cache build-base git postgresql16-dev sqlite-dev yaml-dev
EOT

# MARK: Builder
#
# BUNDLE_APP_CONFIG overrides the ruby image's /usr/local/bundle, so the
# bundler config lands next to the vendored gems and both cross into the
# runtime stage in one copy. The runtime stage sets the same path by hand,
# because an ENV block cannot reference a variable it sets itself; the two
# spellings must agree.
#
# hadolint reads `build-${DISTRO}` as an untagged external image because it
# cannot resolve the build argument. The stage it names is defined above.
# hadolint ignore=DL3006
FROM build-${DISTRO} AS builder
ENV HOME=/pact_broker
ENV BUNDLE_APP_CONFIG=$HOME/.bundle
WORKDIR $HOME
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN /bin/sh <<'EOT'
set -eu
gem install bundler -v "$(awk '/BUNDLED WITH/{getline; print $1}' Gemfile.lock)"
bundle config set deployment 'true'
bundle config set no-cache 'true'
bundle config set without 'development test'
bundle install
rm -rf vendor/bundle/ruby/*/cache .bundle/cache
find vendor/bundle \
  \( -name Gemfile.lock -o -name package-lock.json \) -delete
find vendor/bundle \
  \( -name '*.pem' -o -name '*.key' -o -name '*.java' -o -name '*.jar' \) \
  \( -path '*sample*' -o -path '*test*' -o -path '*spec*' \) -delete
EOT

# MARK: Runtime
#
# hadolint ignore=DL3006
FROM runtime-${DISTRO} AS runtime
ARG TARGETARCH
ARG VERSION=dev

# Scarf analytics - version/platform reported by the entrypoint on startup
ENV HOME=/pact_broker \
    BUNDLE_APP_CONFIG=/pact_broker/.bundle \
    PACT_BROKER_DOCKER_VERSION=${VERSION} \
    PACT_BROKER_DOCKER_PLATFORM=linux-${TARGETARCH} \
    RUBYOPT="-W:no-experimental" \
    RACK_ENV=production \
    PACT_BROKER_DATABASE_CLEAN_ENABLED=false \
    PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE="15 2 * * *" \
    PACT_BROKER_DATABASE_CLEAN_DELETION_LIMIT=500 \
    PACT_BROKER_DATABASE_CLEAN_OVERWRITTEN_DATA_MAX_AGE=7 \
    PACT_BROKER_DATABASE_CLEAN_DRY_RUN=false

WORKDIR $HOME
COPY --from=builder --chown=ruby:root $HOME/vendor $HOME/vendor
COPY --from=builder --chown=ruby:root $HOME/.bundle $HOME/.bundle
COPY --chown=ruby:root pact_broker $HOME/
RUN /bin/sh <<'EOT'
set -eu
gem install bundler -v "$(awk '/BUNDLED WITH/{getline; print $1}' Gemfile.lock)"
mv /pact_broker/clean.sh /usr/local/bin/clean
ln -s /pact_broker/script/db-migrate.sh /usr/local/bin/db-migrate
ln -s /pact_broker/script/db-version.sh /usr/local/bin/db-version
EOT

USER ruby
ENTRYPOINT ["sh", "./entrypoint.sh"]
CMD ["config.ru"]

# MARK: Contract
#
# Build-time assertions that the runtime image carries no build tooling. Built
# by CI with --target contract; never published.
FROM runtime AS contract
# The assertions inspect the installed packages, and this stage is a build-time
# target that is never published.
# hadolint ignore=DL3002
USER root
RUN /bin/sh <<'EOT'
set -eu

for forbidden in gcc g++ cc make git supercronic; do
  if command -v "$forbidden" >/dev/null 2>&1; then
    echo "FAIL: $forbidden is present in the runtime image" >&2
    exit 1
  fi
done

if [ -e /pact_broker/crontab ]; then
  echo "FAIL: stale crontab present in the runtime image" >&2
  exit 1
fi

if command -v apk >/dev/null 2>&1; then
  if apk info 2>/dev/null | grep -q -- '-dev$'; then
    echo "FAIL: -dev packages present:" >&2
    apk info | grep -- '-dev$' >&2
    exit 1
  fi
fi

if command -v dpkg-query >/dev/null 2>&1; then
  if dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -q -- '-dev$'; then
    echo "FAIL: -dev packages present:" >&2
    dpkg-query -W -f='${Package}\n' | grep -- '-dev$' >&2
    exit 1
  fi
fi

bundle exec puma --version
# The clean scheduler needs fugit, and fugit needs the zoneinfo database that
# Alpine does not ship by default.
bundle exec ruby -e 'require "fugit"; Fugit::Cron.parse("15 2 * * *") or abort("cron parse failed")'
echo "PASS: runtime image carries no build tooling"
EOT
