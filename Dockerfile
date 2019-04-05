FROM ubuntu:18.04

# Installation path
ENV HOME=/pact_broker
WORKDIR $HOME

# Setup pact_broker user & install application dependencies
RUN set -ex && \
    chmod g+w $HOME && \
    useradd --home-dir $HOME --gid root --system pact_broker && \
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

# Install Gems & Passenger Standalone
COPY pact_broker/Gemfile pact_broker/Gemfile.lock $HOME/
RUN set -ex && \
    bundle install --no-cache --deployment --without='development test' && \
    rm -rf vendor/bundle/ruby/*/cache .bundle/cache && \
    bundle exec passenger-config install-agent && \
    bundle exec passenger-config install-standalone-runtime && \
    bundle exec passenger-config build-native-support

# Install source
COPY pact_broker $HOME/

# Start Passenger
USER pact_broker
EXPOSE 3000
ENTRYPOINT ["bundle", "exec", "passenger"]
CMD ["start", "--log_file", "/dev/stdout"]
