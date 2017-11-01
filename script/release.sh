DOCKER_IMAGE="dius/pact-broker"

export TAG=$(script/next-docker-tag.sh)
bundle exec rake generate_changelog
git add CHANGELOG.md && git commit -m "chore(changelog): update for ${TAG}"
echo "Tagging version ${TAG}"
git tag -a "${TAG}" -m "Releasing version ${TAG}" && git push origin "${TAG}"
