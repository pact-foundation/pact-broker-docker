#Builds the pact broker image
docker build -t=pact_broker_img .

docker run --name broker_app \
  -e DB_USERNAME=$BROKER_DB_USERNAME \
  -e DB_PASSWORD=$BROKER_DB_PASSWORD \
  -e DB_HOST=$BROKER_DB_HOST \
  -e DB_NAME=$BROKER_DB_NAME \
  -w /app \
  -d -p 9292:9292 pact_broker_img
