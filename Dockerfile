# Dockerise the pact-broker

FROM phusion/baseimage

RUN rm -rf /etc/nginx

RUN apt-get update -q

RUN /usr/bin/workaround-docker-2267

EXPOSE 80
ENV HOME /root
CMD ["/sbin/my_init"]

WORKDIR /tmp
ADD Gemfile Gemfile
RUN bundle install

ADD ./ /app
ADD ./container /
