# Dockerise the pact-broker

FROM phusion/baseimage

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  ruby-full

RUN gem install bundler

RUN /usr/bin/workaround-docker-2267

ENV HOME /root
CMD ["/sbin/my_init"]

ADD . /app

WORKDIR /app
ADD Gemfile Gemfile
RUN bundle install

RUN mkdir /etc/service/app
ADD boot_app.sh /etc/service/app/run
