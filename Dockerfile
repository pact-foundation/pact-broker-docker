FROM phusion/passenger-ruby22:0.9.15

EXPOSE 80
ENV HOME /root
CMD ["/sbin/my_init"]
RUN rm -f /etc/service/nginx/down

RUN rm /etc/nginx/sites-enabled/default
ADD webapp.conf /etc/nginx/sites-enabled/webapp.conf
ADD pactbroker-env.conf /etc/nginx/main.d/pactbroker-env.conf

RUN mkdir -p /home/app/pact_broker
RUN mkdir /home/app/pact_broker/public
RUN mkdir /home/app/pact_broker/tmp

WORKDIR /home/app/pact_broker
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --deployment
ADD config.ru config.ru
RUN chown -R app:app /home/app/pact_broker
