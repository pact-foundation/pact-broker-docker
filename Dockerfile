FROM ruby:2.6.6-alpine

# Installation path
ENV HOME=/pact_broker

# Setup ruby user & install application dependencies
RUN set -ex && \
  adduser -h $HOME -s /bin/false -D -S -G root ruby && \
  chmod g+w $HOME && \
  apk add --update --no-cache make gcc libc-dev mariadb-dev postgresql-dev sqlite-dev git

# Install Gems
WORKDIR $HOME
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN cat Gemfile.lock | grep -A1 "BUNDLED WITH" | tail -n1 | awk '{print $1}' > BUNDLER_VERSION
RUN set -ex && \
  gem install bundler -v $(cat BUNDLER_VERSION) && \
  ls /usr/local/lib/ruby/gems/2.6.0 && \
  gem uninstall --install-dir /usr/local/lib/ruby/gems/2.6.0 -x rake && \
  find /usr/local/lib/ruby -name webrick* -exec rm -rf {} + && \
  bundle config set deployment 'true' && \
  bundle config set no-cache 'true' && \
  bundle install --without='development test' && \
  rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
  apk del make gcc libc-dev git

# Install source
COPY pact_broker $HOME/

# Start Puma
ENV RACK_ENV=production
ENV PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME=PACT_BROKER_PORT
ENV PACT_BROKER_PORT=9292
USER ruby
ENTRYPOINT ["./entrypoint.sh"]
CMD ["config.ru"]
