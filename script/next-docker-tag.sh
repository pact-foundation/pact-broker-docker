DOCKER_IMAGE="pactfoundation/pact-broker"
gem_version=$(ruby -e "require 'pact_broker/version'; puts PactBroker::VERSION")
existing_tags=$(wget -q https://registry.hub.docker.com/v1/repositories/${DOCKER_IMAGE}/tags -O - | jq -r .[].name)
existing_release_numbers_for_current_gem_version=$(echo "$existing_tags" | grep "${gem_version}-" | sed 's/'${gem_version}'-//g')
last_release_number=$(printf "0\n${existing_release_numbers_for_current_gem_version}" | sort -g | tail -1)
next_release_number=$[$last_release_number+1]
tag="${gem_version}-${next_release_number}"
echo $tag
