# Dockerise the pact-broker

FROM phusion/baseimage

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  ruby-full

RUN gem install bundler

EXPOSE 80
ENV HOME /root
CMD ["/etc/service/app/run"]

ADD . /app

WORKDIR /app
ADD Gemfile Gemfile
RUN bundle install

RUN mkdir /etc/service/app
ADD boot_app.sh /etc/service/app/run
