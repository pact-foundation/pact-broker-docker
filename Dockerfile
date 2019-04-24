FROM ruby:2.6-alpine

# Installation path
ENV HOME=/pact_broker
WORKDIR $HOME

# Setup ruby user & install application dependencies
RUN set -ex && \
    chmod g+w $HOME && \
    adduser -h $HOME -s /bin/false -D -S -G root ruby && \
    apk add --update --no-cache make gcc libc-dev mariadb-dev postgresql-dev sqlite-dev

# Install Gems
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
