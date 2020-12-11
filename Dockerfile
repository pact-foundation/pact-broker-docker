FROM ruby:2.6.6-alpine as Base 

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.11/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=a2e2d47078a8dafc5949491e5ea7267cc721d67c

RUN wget "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Installation path
ENV HOME=/pact_broker
WORKDIR $HOME

# Setup ruby user & install application dependencies
RUN set -ex && \
  adduser -h $HOME -s /bin/false -D -S -G root ruby && \
  chmod g+w $HOME

RUN set -ex && \
  apk add --update --no-cache mariadb-dev postgresql-dev sqlite-dev

FROM Base as Builder

# Install Gems
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN cat Gemfile.lock | grep -A1 "BUNDLED WITH" | tail -n1 | awk '{print $1}' > BUNDLER_VERSION
RUN set -ex && \
  apk add --update --no-cache make gcc libc-dev git && \
  gem install bundler -v $(cat BUNDLER_VERSION) && \
  ls /usr/local/lib/ruby/gems/2.6.0 && \
  bundle config set deployment 'true' && \
  bundle config set no-cache 'true' && \
  bundle install --without='development test' && \
  rm -rf vendor/bundle/ruby/*/cache .bundle/cache 

FROM Base

# Copy app with gems from former build stage
COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=Builder --chown=ruby:root $HOME $HOME

RUN set -ex && \
  gem uninstall --install-dir /usr/local/lib/ruby/gems/2.6.0 -x rake && \
  find /usr/local/lib/ruby -name webrick* -exec rm -rf {} + && \ 
  bundle config set deployment 'true' 
  
# Install source
COPY pact_broker $HOME/

# Start Puma
ENV RACK_ENV=production
ENV PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME=PACT_BROKER_PORT
ENV PACT_BROKER_DATABASE_BETA_CLEAN_ENABLED=false
ENV PACT_BROKER_DATABASE_CLEAN_CRON_SCHEDULE="0 2 15 * *"
ENV PACT_BROKER_DATABASE_CLEAN_KEEP_VERSION_SELECTORS='[{ "latest": true, "tag": true }, { "max_age": 90 }]'
ENV PACT_BROKER_DATABASE_CLEAN_DELETION_LIMIT=500
ENV PACT_BROKER_DATABASE_CLEAN_OVERWRITTEN_DATA_MAX_AGE=7
ENV PACT_BROKER_DATABASE_CLEAN_DRY_RUN=false
ENV PACT_BROKER_PORT=9292
USER ruby

ENTRYPOINT ["./entrypoint.sh"]
CMD ["config.ru"]
