## Updating the Pact Broker gems

    cd pact_broker
    bundle update

    # Check Pact Broker can start
    PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite be rackup

    # Run test script
    cd ..
    PACT_BROKER_DATABASE_NAME=pact_broker.sqlite PACT_BROKER_DATABASE_ADAPTER=sqlite script/test.sh

    # Commit changes
    git add pact_broker
    git commit -m "chore(gems): Updated pact_broker gem to version $(cd pact_broker && bundle exec ruby -e "require 'pact_broker/version'; puts PactBroker::VERSION")"
    git push

## Publishing to Docker Hub

Docker hub will build an image every time a tag with pattern /^[0-9.\-]+/ (eg. 2.3.0-1) is pushed.

To release a new image with a tag:

    script/release.sh
