#!/bin/sh

set -euo >/dev/null

docker_compose_files=$(find . -name "docker-compose*.yml" -not -name "*test*")

for file in $docker_compose_files; do
  cat $file | sed -e "s~image: pactfoundation/pact-broker:.*~image: pactfoundation/pact-broker:${TAG}~g" > dc-tmp
  mv dc-tmp $file
done

bundle exec conventional-changelog version=${TAG} force=true
git add CHANGELOG.md
git add docker-compose*
git commit -m "chore(release): version ${TAG}"
