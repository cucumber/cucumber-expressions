# Releasing

There are two parts to making a release. First, prepare the release, then make the release.

## Preparing a release

Anyone with permission to push to the `main` branch can prepare a release.
To make these steps easier, you can use the [`changelog`](https://github.com/cucumber/changelog) tool.

1. Make sure the CI badges in `README.md` indicate passing
1. Decide what the next version number should be
   * Look at `CHANGELOG.md` to see what has changed since the last relesase
   * Use [semver](https://semver.org/) to pick a version for the next release.
     ```
     read $next_release
     ```
1. Modify the changelog:
   ```
   changelog release $next_release -o CHANGELOG.md
   ```
   * If you don't have `changelog` installed, do it manually:
     * Under `[Unreleased]` at the top, add a new `[${version}] - ${YYYY-mm-dd}` header
     * Add a new `[${version}]` link at the bottom
     * Update the `[Unreleased]` link at the bottom
1. Update the version numbers in package descriptors:
   * `java/pom.xml` (`${version}-SNAPSHOT`)
   * `javascript/package.json`
   * `ruby/VERSION`
1. Commit and push
   ```
   git add .
   git commit -m "Release $next_release"
   git push
   ```

### Making a release

Only people with permission to push to `release/*` branches can make releases.

1. Push to a new `release/*` branc
   ```
   git checkout -b release/v$next_release
   git push --set-upstream origin release/v$next_release
   ```
   * This will trigger the [`release-*` workflow](https://github.com/cucumber/cucumber-expressions/actions).
1. Monitor the `release-*` workflows in GitHub Actions
1. Rerun individual workflows if they fail
1. Consider announcing the release on Slack/Twitter/Blog
