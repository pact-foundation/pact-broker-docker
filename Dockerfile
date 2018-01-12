# ubuntu:14.04 -- https://hub.docker.com/_/ubuntu/
# |==> phusion/baseimage:0.9.17 -- https://goo.gl/ZLt61q
#      |==> phusion/passenger-ruby22:0.9.17 -- https://goo.gl/xsnWOP
#           |==> HERE
FROM phusion/passenger-ruby24:0.9.26

ENV APP_HOME=/home/app/pact_broker/
RUN rm -f /etc/service/nginx/down /etc/nginx/sites-enabled/default
COPY container /
RUN gem update --system
# USER app

COPY pact_broker/config.ru pact_broker/Gemfile pact_broker/Gemfile.lock $APP_HOME
# Update system gems for:
# https://www.ruby-lang.org/en/news/2017/08/29/multiple-vulnerabilities-in-rubygems/
RUN gem install bundler && \
    cd $APP_HOME && bundle install --deployment --without='development test'
COPY pact_broker/ $APP_HOME/
RUN chown -R app:app $APP_HOME

EXPOSE 80
CMD ["/sbin/my_init"]
