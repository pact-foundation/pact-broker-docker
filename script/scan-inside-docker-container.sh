#!/usr/bin/env sh
set -eu

wget -q -O - https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/install.sh | sh -s -- -b /usr/local/bin
trivy filesystem --exit-code 1 --no-progress /
