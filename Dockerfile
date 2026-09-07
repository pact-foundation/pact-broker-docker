FROM ruby:3.4.10-alpine3.24@sha256:c5a5064d190055633011c03aa800170cc36945ff3afb5f6c915329f92d6f1e00 AS base

# gcompat is a musl compatibility shim. nokogiri needs it on arm and arm64,
# where the network graph breaks without it
# (https://github.com/sparklemotion/nokogiri/issues/2414). It is installed on
# every architecture so the build has no architecture-conditional branch.
#
# tzdata supplies the zoneinfo database. Alpine ships none, and the clean
# scheduler's `require "fugit"` fails outright without it.
RUN apk add --update --no-cache gcompat tzdata

FROM base AS pb-dev

# Scarf analytics - version/platform reported by the entrypoint on startup
ARG TARGETARCH
ARG VERSION=dev
ENV PACT_BROKER_DOCKER_VERSION=${VERSION} \
    PACT_BROKER_DOCKER_PLATFORM=linux-${TARGETARCH}

# Installation path
ENV HOME=/pact_broker

# Setup ruby user & install application dependencies
RUN set -ex && \
  adduser -h $HOME -s /bin/false -D -S -G root ruby && \
  chmod g+w $HOME

# Install Gems
WORKDIR $HOME
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN cat Gemfile.lock | grep -A1 "BUNDLED WITH" | tail -n1 | awk '{print $1}' > BUNDLER_VERSION
RUN set -ex && \
  apk add --update --no-cache make gcc libc-dev postgresql16-dev sqlite-dev git yaml-dev && \
  apk upgrade && \
  gem install bundler -v $(cat BUNDLER_VERSION) && \
  bundle config set deployment 'true' && \
  bundle config set no-cache 'true' && \
  bundle config set without 'development test' && \
  bundle install && \
  rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
  find $HOME/vendor/bundle /usr/local/lib/ruby/gems \
      \( -name Gemfile.lock -o -name package-lock.json \) -exec rm -rf {} + && \
  find $HOME/vendor/bundle /usr/local/lib/ruby/gems \
      \( -name *.pem -o -name *.key -o -name *.java -o -name *.jar \)  | \
      grep -e sample -e test -e spec | xargs rm -rf {} + && \
  apk del make gcc libc-dev git

# Install source
COPY pact_broker $HOME/
RUN mv $HOME/clean.sh /usr/local/bin/clean

RUN ln -s /pact_broker/script/db-migrate.sh /usr/local/bin/db-migrate
RUN ln -s /pact_broker/script/db-version.sh /usr/local/bin/db-version

# Hide pattern matching warnings
ENV RUBYOPT="-W:no-experimental"

# Start Puma
ENV RACK_ENV=production
ENV PACT_BROKER_DATABASE_CLEAN_ENABLED=false
ENV PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE="15 2 * * *"
ENV PACT_BROKER_DATABASE_CLEAN_DELETION_LIMIT=500
ENV PACT_BROKER_DATABASE_CLEAN_OVERWRITTEN_DATA_MAX_AGE=7
ENV PACT_BROKER_DATABASE_CLEAN_DRY_RUN=false
USER ruby
ENTRYPOINT ["sh", "./entrypoint.sh"]
CMD ["config.ru"]
