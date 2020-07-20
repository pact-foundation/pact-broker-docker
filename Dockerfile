FROM ruby:2.6.4-alpine

# Installation path
ENV HOME=/pact_broker

# Setup ruby user & install application dependencies
RUN set -ex && \
  adduser -h $HOME -s /bin/false -D -S -G root ruby && \
  chmod g+w $HOME && \
  apk add --update --no-cache make gcc libc-dev mariadb-dev postgresql-dev sqlite-dev

# Install Gems
WORKDIR $HOME
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN set -ex && \
  gem install bundler -v 2.1.4 && \
  bundle install --no-cache --deployment --without='development test' && \
  rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
  apk del make gcc libc-dev

# Install source
COPY pact_broker $HOME/

# Start Puma
ENV RACK_ENV=production
ENV PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME=PACT_BROKER_PORT
ENV PACT_BROKER_PORT=9292
USER ruby
ENTRYPOINT ["./entrypoint.sh"]
CMD ["config.ru"]
