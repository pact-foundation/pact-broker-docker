# set -x

if [ -z "$1" ]; then
  BASE_URL="http://localhost"
else
  BASE_URL="$1"
fi

BODY=$(ruby -e "require 'json'; j = JSON.parse(File.read('script/foo-bar.json')); j['interactions'][0]['providerState'] = 'it is ' + Time.now.to_s; puts j.to_json")
echo ${BODY} >> tmp.json
curl -v -XPUT -u foo:bar \-H "Content-Type: application/json" \
-d@tmp.json \
${BASE_URL}/pacts/provider/Bar/consumer/Foo/version/1.1.0
rm tmp.json
echo ""
