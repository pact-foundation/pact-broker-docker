# Releasing

Please read the [versioning](/#versioning) section of the README file before continuing.

The semantic version part of the Docker tag is stored in the `VERSION` file at
the root of the repository. The full tag is `${VERSION}-pactbroker${GEM_VERSION}`,
where the gem version comes from `pact_broker/Gemfile.lock`.

## One-time prerequisite

`prepare` computes the next version from the conventional commits since the
last `v*` tag. This repository's existing tags are of the form `2.98.0.0`, not
`v2.98.0.0`, so before the first release under this process, create and push a
`v<current VERSION>` tag on `master` (today that is `v2.142.0`) to give
git-cliff a starting point:

    git tag v2.142.0 master && git push origin v2.142.0

Push it as someone whose access clears any tag protection rule. Until this tag
exists, `prepare` finds nothing releasable and prints "nothing to do" on every
run, silently.

Releases are made by merging a pull request.

Every push to `master` updates a draft pull request from the
`release/pact-broker-docker` branch. It contains the next version, computed from
the conventional commits since the last tag, the changelog entry for it, and the
updated image references in the `docker-compose*.yml` files.

To release:

1. Open the draft `chore: release vX.Y.Z` pull request and check the changelog.
   Opening it already builds and tests both the alpine and debian images
   against the release commit — that runs on push to the branch, not on
   marking the PR ready for review.
2. Mark it ready for review once the checks pass.
3. Merge it. The tag `vX.Y.Z` is pushed, which publishes both images to Docker
   Hub and GHCR and creates the GitHub release.

## Releases triggered by a pact_broker gem release

Renovate opens the `pact_broker/Gemfile.lock` update, immediately and with no
cool-off period, and auto-merges it. Merging updates the release pull request
above.

The changelog skips dependency bumps, except the ones that change what the
image ships or serves: the `pact_broker` gem, whose entry links to that gem's
GitHub release, puma, the ruby/alpine/debian base and postgres.

## Seeing what the next release would contain

    ruby script/release.rb prepare --dry-run

This writes the new version, changelog and compose references into the working
tree and prints the entry. Discard the changes with
`git checkout -- VERSION CHANGELOG.md docker-compose*.yml`.

## Pushing a non-production image

Set `TAG` and run the release scripts locally. The `VERSION` file is not
updated and no git tag is created, and the image is not pushed to `latest`
unless you also set `PUSH_TO_LATEST=true`.

`docker-push.sh` reads `GITHUB_SERVER_URL`, `GITHUB_REPOSITORY` and
`GITHUB_SHA` for image annotations, so set them too when running outside
Actions:

    TAG=my-test-tag DOCKER_REPOSITORY=my-org \
      GITHUB_SERVER_URL=https://github.com GITHUB_REPOSITORY=my-org/pact-broker-docker GITHUB_SHA=$(git rev-parse HEAD) \
      script/release-workflow/run.sh
