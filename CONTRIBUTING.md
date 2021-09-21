Everyone contributing to this repo is expected to abide by the [Cucumber Community Code of Conduct](https://cucumber.io/conduct).

## Making a release

There are two parts to making a release. First, prepare the release, then make the release.

### Preparing a release

Anyone with commit rights to `main` can prepare a release.

To make these steps easier, can use the [`changelog`](https://github.com/rcmachado/changelog) tool.

First, make sure your changes are detailed in the `Unreleased` section of the [CHANGELOG](./CHANGELOG.md) file.

Then, use [semver](https://semver.org/) to pick a version for the next release.

    read $next_release

Modify the changelog:

    changelog release $next_release -o CHANGELOG.md

Commit and push

     git add .
     git commit -m "Release $next_release"

### Making a release

Only people with rights to push to the `release/*` branches can make releases.

    git checkout -b release/v$next_release
    git push

This will trigger the [`release` workflow](https://github.com/cucumber/cucumber-expressions/actions/workflows/release.yaml).
