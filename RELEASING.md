# Releasing

Please read the [versioning](/#versioning) section of the README file before continuing.

The semantic version part of the tag is stored in the `VERSION` file at the root of the repository.

## Automatic releases of the Docker image triggered by the release of the pact_broker gem

When the pact_broker gem is released by the Github Action in its repository, the `repository_dispatch` action of the `pact-broker-docker` repository will be invoked with the type `gem-released`, and the release details (name, version, increment).

This causes the `update_gems.yml` workflow to be run. At the end of the workflow, it will trigger a release by invokeing the `repository_dispatch` action with type `release-triggered`, passing in the increment.

Note: sometimes bundler cannot find the newly released gem straight away, and the job needs to be re-run via the UI.

## Manually releasing the Docker image

* On the Github Actions page, select `Release Docker image`
* Select `Run workflow`
* To release a minor version change, do not set any inputs - just click `Run workflow`. This should be the normal process if you've done some changes to the Docker image.
* To release a non-minor version change, select the increment you want, and click `Run workflow`.
* To set a custom version number (not sure of the usecase for this, but just in case...), set both the version AND the increment and click `Run workflow`.
* To do a completely custom tag, just set the "Custom Docker image tag" and click `Run workflow`. If you do this, the VERSION file will NOT be updated. It is for testing purposes only.
