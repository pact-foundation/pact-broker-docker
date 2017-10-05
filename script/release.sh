DOCKER_IMAGE="dius/pact-broker"

echo "Tagging version ${TAG}"
git tag -a "${TAG}" -m "Releasing version ${TAG}" && git push origin "${TAG}"
