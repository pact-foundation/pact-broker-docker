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
RUN <<'EOT' /bin/sh
set -eu
apk upgrade --no-cache
apk add --no-cache gcompat libpq sqlite-libs tzdata yaml
adduser -h /pact_broker -s /bin/false -D -S -G root ruby
chmod g+w /pact_broker
EOT

FROM runtime-alpine AS build-alpine
RUN <<'EOT' /bin/sh
set -eu
apk add --no-cache build-base git postgresql16-dev sqlite-dev yaml-dev
EOT

# MARK: Debian
#
# Runs on -slim rather than ruby:3.4. The latter is buildpack-deps and ships a
# full toolchain before the first instruction, so a clean runtime image is not
# reachable from it. build-essential is installed explicitly rather than
# inherited, so the builder's contents are stated rather than implied.
#
# The slim base already carries tzdata, libsqlite3-0 and libyaml-0-2. The
# runtime list names them anyway: apt is idempotent, and a dependency the image
# relies on is worth stating.
FROM ruby:3.4.10-slim@sha256:9d50d98e61ccbe4f1ef436349911e09b53c42a00364bcd3bda6ac107abc29528 AS runtime-debian
# The base image ships security updates behind its own release cadence, so the
# upgrade runs here rather than in build-debian and reaches the shipped layer.
RUN <<'EOT' /bin/sh
set -eu
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libpq5 \
  libsqlite3-0 \
  libyaml-0-2 \
  tzdata
apt-get clean
rm -rf /var/lib/apt/lists/*
useradd -d /pact_broker -m -s /bin/false -r -g root ruby
chmod g+w /pact_broker
EOT

# pkg-config is listed because the sqlite3 gem's extconf refuses to configure
# without it, and build-essential does not pull it in.
FROM runtime-debian AS build-debian
RUN <<'EOT' /bin/sh
set -eu
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  git \
  libpq-dev \
  libsqlite3-dev \
  libyaml-dev \
  pkg-config
apt-get clean
rm -rf /var/lib/apt/lists/*
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
RUN <<'EOT' /bin/sh
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
RUN <<'EOT' /bin/sh
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
RUN <<'EOT' /bin/sh
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

# The package list is captured first so that a failing query aborts the stage.
# Piping the query straight into grep would report grep's status, and a base
# with no package manager would read as "no -dev packages installed".
if command -v apk >/dev/null 2>&1; then
  packages="$(apk info)"
elif command -v dpkg-query >/dev/null 2>&1; then
  packages="$(dpkg-query -W -f='${Package}\n')"
else
  echo "FAIL: no package query tool, cannot enumerate installed packages" >&2
  exit 1
fi

if printf '%s\n' "$packages" | grep -q -- '-dev$'; then
  echo "FAIL: -dev packages present:" >&2
  printf '%s\n' "$packages" | grep -- '-dev$' >&2
  exit 1
fi

bundle exec puma --version
# The clean scheduler needs fugit, and fugit needs the zoneinfo database that
# Alpine does not ship by default.
bundle exec ruby -e 'require "fugit"; Fugit::Cron.parse("15 2 * * *") or abort("cron parse failed")'
# resolv ships as a default gem; the bundle must supersede it to clear CVE-2026-80212.
bundle exec ruby -e 'require "resolv"; v = Gem.loaded_specs.fetch("resolv").version; abort("resolv #{v} is older than 0.7.2") if v < Gem::Version.new("0.7.2")'
echo "PASS: runtime image carries no build tooling"
EOT

# The contract stage is last in the file, so a plain `docker build .` lands here.
# Restoring the runtime user keeps that default image unprivileged.
USER ruby
