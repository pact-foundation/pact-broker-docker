# ubuntu:14.04 -- https://hub.docker.com/_/ubuntu/
# |==> phusion/baseimage:0.9.17 -- https://goo.gl/ZLt61q
#      |==> phusion/passenger-ruby22:0.9.17 -- https://goo.gl/xsnWOP
#           |==> HERE
FROM phusion/passenger-ruby22:0.9.17

EXPOSE 80
ENV APP_HOME=/home/app/pact_broker
CMD ["/sbin/my_init"]
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD container /

ADD pact_broker/config.ru $APP_HOME/
ADD pact_broker/Gemfile $APP_HOME/
ADD pact_broker/Gemfile.lock $APP_HOME/
RUN chown -R app:app $APP_HOME

# Update system gems for:
# https://www.ruby-lang.org/en/news/2017/08/29/multiple-vulnerabilities-in-rubygems/
RUN gem update --system
RUN gem install bundler
RUN su app -c "cd $APP_HOME && bundle install --deployment --without='development test'"
ADD pact_broker/ $APP_HOME/
RUN chown -R app:app $APP_HOME
