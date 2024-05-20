FROM ruby:3.3.1-alpine3.19 as base

# 1. Install target specfic dependencies
# - gcompat required for arm/arm64 (otherwise nokogiri breaks when viewing network graph)
#   - https://github.com/sparklemotion/nokogiri/issues/2414
# 2. Supercronic - setup sha1sum for each supported architecture
FROM base AS base-amd64
ENV SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b
FROM base AS base-arm64
ENV SUPERCRONIC_SHA1SUM=512f6736450c56555e01b363144c3c9d23abed4c
RUN apk add --update --no-cache gcompat
FROM base AS base-arm
ENV SUPERCRONIC_SHA1SUM=75e065bf0909f920b06d5bd797c0e6b31e68b112
RUN apk add --update --no-cache gcompat

# Supercronic - use base-$TARGETARCH to select correct base image SUPERCRONIC_SHA1SUM
ARG TARGETARCH
FROM base-$TARGETARCH AS pb-dev

# Install Supercronic
ARG TARGETARCH
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-${TARGETARCH} \
    SUPERCRONIC=supercronic-linux-${TARGETARCH}
RUN wget "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

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
  apk add --update --no-cache make gcc libc-dev mariadb-dev postgresql14-dev sqlite-dev git && \
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
