FROM 1and1internet/ubuntu-16-nginx-passenger-ruby-2.3
ENV APP_HOME=/home/app/pact_broker/
RUN apt-get update && apt-get install libpq-dev --yes &&
rm -f /etc/service/nginx/down /etc/nginx/sites-enabled/default

COPY container /
RUN gem update --system
COPY pact_broker/config.ru pact_broker/Gemfile pact_broker/Gemfile.lock $APP_HOME
RUN chgrp -R 0 $APP_HOME && chmod -R g=u $APP_HOME
RUN gem install bundler && cd $APP_HOME && bundle install --deployment --without='development test'

COPY pact_broker/ $APP_HOME/
RUN chgrp -R 0 $APP_HOME && chmod -R g=u $APP_HOME

EXPOSE 8080
