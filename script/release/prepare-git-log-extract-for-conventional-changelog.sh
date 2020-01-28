#!/usr/bin/env sh
# Extracts the relevant commits from the git log for this release

set -e

rm -rf tmp; mkdir -p tmp

export DELIMITER="/////"

last_tag=$(grep "a name=" CHANGELOG.md | head -n 1 | cut -d \" -f2)

# Use the same command that conventional-changelog uses to extract the relevant
# lines from the git log
# See https://github.com/dcrec1/conventional-changelog-ruby/blob/628565d00caed1f93461a3cd189fb40452066e71/lib/conventional_changelog/git.rb#L17-L20

git log --pretty=format:"%h${DELIMITER}%ad${DELIMITER}%s%x09" \
    --date=short \
    --grep="^(feat|fix)(\\(.*\\))?:" \
    -E \
    ${last_tag}..HEAD > tmp/git-log

echo "Extracted the following commits since ${last_tag}:"
cat tmp/git-log
echo ""
