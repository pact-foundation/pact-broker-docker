#Start DB and app
docker build -t=app_img .

docker run --name broker_db -d postgres
docker run --name broker_app --link broker_db:postgres -d app_img
