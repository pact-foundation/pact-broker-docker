FROM ruby:3.2.2-slim as base
FROM base AS base-amd64
ENV SUPERCRONIC_SHA1SUM=7a79496cf8ad899b99a719355d4db27422396735
FROM base AS base-arm64
ENV SUPERCRONIC_SHA1SUM=e4801adb518ffedfd930ab3a82db042cb78a0a41
FROM base AS base-arm
ENV SUPERCRONIC_SHA1SUM=d8124540ebd8f19cc0d8a286ed47ac132e8d151d
ARG TARGETARCH
FROM base-$TARGETARCH AS pb-dev
ARG TARGETARCH
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.26/supercronic-linux-${TARGETARCH} \
    SUPERCRONIC=supercronic-linux-${TARGETARCH}
RUN apt-get update -y && apt-get -y install wget
RUN wget "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
ENV HOME=/pact_broker
WORKDIR $HOME
RUN adduser --system --group --no-create-home --home $HOME --shell /bin/false --disabled-login ruby && chmod g+w $HOME
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN cat Gemfile.lock | grep -A1 "BUNDLED WITH" | tail -n1 | awk '{print $1}' > BUNDLER_VERSION
RUN set -ex && \
  apt-get -y install make gcc libc-dev libmariadb-dev libpq-dev libsqlite3-dev git && \
  gem install bundler -v $(cat BUNDLER_VERSION) && \
  bundle config set deployment 'true' && \
  bundle config set no-cache 'true' && \
  bundle config set without 'development test' && \
  bundle install
COPY pact_broker $HOME/
RUN mv $HOME/clean.sh /usr/local/bin/clean
RUN ln -s /pact_broker/script/db-migrate.sh /usr/local/bin/db-migrate
RUN ln -s /pact_broker/script/db-version.sh /usr/local/bin/db-version
ENV RUBYOPT="-W:no-experimental"
ENV RACK_ENV=production
ENV PACT_BROKER_DATABASE_CLEAN_ENABLED=false
ENV PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE="15 2 * * *"
ENV PACT_BROKER_DATABASE_CLEAN_DELETION_LIMIT=500
ENV PACT_BROKER_DATABASE_CLEAN_OVERWRITTEN_DATA_MAX_AGE=7
ENV PACT_BROKER_DATABASE_CLEAN_DRY_RUN=false
USER ruby
ENTRYPOINT ["sh", "./entrypoint.sh"]
CMD ["config.ru"]