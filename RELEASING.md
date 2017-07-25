## Publishing to Docker Hub

Docker hub will build an image every time master or a tag with pattern /^[0-9.\-]+/ (eg. 2.3.0-1) is pushed.

To release a new `latest`:

    git push origin master

To release a new image with a tag:

    # Set the release number manually based on existing releases
    # at https://hub.docker.com/r/dius/pact-broker/tags/
    export RELEASE="6"
    export PACT_BROKER_GEM_VERSION=$(cat pact_broker/Gemfile.lock | grep  "pact_broker" | egrep -o "[0-9][0-9\.]+[0-9]")
    git tag -a ${PACT_BROKER_GEM_VERSION}-${RELEASE} -m "Releasing v${PACT_BROKER_GEM_VERSION}-${RELEASE}" && git push origin --tags