FROM ruby:2.6-alpine

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
    bundle install --no-cache --deployment --without='development test' && \
    rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
    apk del make gcc libc-dev

# Install source
COPY pact_broker $HOME/

# Start Puma
ENV RACK_ENV=production
USER ruby
EXPOSE 9292
ENTRYPOINT ["bundle", "exec", "puma"]
CMD ["config.ru"]
