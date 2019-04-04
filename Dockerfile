FROM ubuntu:18.04

# Install application dependencies
RUN set -ex && \
    useradd --create-home --user-group --system pact && \
    apt-get update && \
    apt-get install -y \
        ruby \
        ruby-dev \
        make \
        build-essential \
        gcc \
        libssl-dev \
        curl \
        libcurl4-openssl-dev \
        default-libmysqlclient-dev \
        libpq-dev \
        libsqlite3-dev && \
    gem install --no-document --minimal-deps bundler -v '~>1.0' && \
    rm -rf /var/lib/gems/*/cache

# Include testing utils
COPY container /

# Set user mode
ENV HOME=/home/pact
WORKDIR $HOME
USER pact

# Install Gems & Passenger Standalone
COPY --chown=pact pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN set -ex && \
    bundle install --no-cache --deployment --without='development test' && \
    rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
    bundle exec passenger-config install-agent && \
    bundle exec passenger-config install-standalone-runtime && \
    bundle exec passenger-config build-native-support

# Install source
COPY --chown=pact pact_broker $HOME/

# Start Passenger
EXPOSE 3000
ENTRYPOINT ["bundle", "exec", "passenger"]
CMD ["start", "--log_file", "/dev/stdout"]
