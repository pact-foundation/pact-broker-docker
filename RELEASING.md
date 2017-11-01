## Updating the Pact Broker gems

Run:

    script/update.sh

This will update to the latest version of the pact broker gem allowable by the Gemfile. Note that if you want to release a beta version, you will need to specify the version explicitly. eg `gem "pact_broker", "2.7.0.beta.3"`

## Debugging

    # Check Pact Broker can start
    PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite be rackup

## Publishing to Docker Hub

Docker hub will build a new `latest` image every time a tag with a major.minor.patch version pattern is pushed. It will build with just the tag name if the version has something like '.beta.1' on the end.

To release a new image with a tag:

    script/release.sh

