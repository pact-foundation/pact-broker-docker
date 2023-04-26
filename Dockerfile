FROM ruby:2.7.8-alpine3.16

ARG SUPERCRONIC_PLATFORM=amd64
ARG SUPERCRONIC_SHA1SUM=2319da694833c7a147976b8e5f337cd83397d6be

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.2/supercronic-linux-${SUPERCRONIC_PLATFORM} \
    SUPERCRONIC=supercronic-linux-${SUPERCRONIC_PLATFORM}

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
  apk add --update --no-cache make gcc libc-dev mariadb-dev postgresql-dev sqlite-dev git && \
  apk upgrade && \
  gem install bundler -v $(cat BUNDLER_VERSION) && \
  ls /usr/local/lib/ruby/gems/2.7.0 && \
  gem install rdoc -v "6.3.2" --install-dir /usr/local/lib/ruby/gems/2.7.0 && \
  gem uninstall --install-dir /usr/local/lib/ruby/gems/2.7.0 -x rake && \
  find /usr/local/lib/ruby -name webrick* -exec rm -rf {} + && \
  find /usr/local/lib/ruby -name rdoc-6.1* -exec rm -rf {} + && \
  bundle config set deployment 'true' && \
  bundle config set no-cache 'true' && \
  bundle config set without 'development test' && \
  bundle install && \
  rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
  find vendor/bundle/ruby/2.7.0/gems -name Gemfile.lock | xargs rm -rf {} + && \
  find /usr/local/bundle/gems/ -name *.pem | grep -e sample -e test | xargs rm -rf {} + && \
  find /usr/local/bundle/gems/ -name *.key | grep -e sample -e test | xargs rm -rf {} + && \
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
