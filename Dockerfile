# Dockerise the pact-broker

FROM phusion/baseimage

RUN apt-get update && apt-get install -y \
  build-essential \
  libsqlite3-dev \
  ruby-full

RUN gem install bundler

RUN /usr/bin/workaround-docker-2267

EXPOSE 80
ENV HOME /root
CMD ["/sbin/my_init"]

ADD ./app /app

WORKDIR /app
ADD app/Gemfile Gemfile
RUN bundle install
