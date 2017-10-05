DOCKER_IMAGE="dius/pact-broker"

[[ -z "${TAG}" ]] && echo "Please set TAG environment variable" && exit 1

echo "Tagging version ${TAG}"
git tag -a "${TAG}" -m "Releasing version ${TAG}" && git push origin "${TAG}"
