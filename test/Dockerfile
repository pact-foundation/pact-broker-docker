FROM powerman/dockerize:0.25.2

RUN apk add --no-cache openssl curl bash jq

COPY test.sh /home/test.sh
COPY clean-test.sh /home/clean-test.sh
COPY foo-bar.json /home/foo-bar.json
