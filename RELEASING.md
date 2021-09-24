# Releasing

There are two parts to making a release. First, prepare the release, then make the release.

## Preparing a release

Anyone with permission to push to the `main` branch can prepare a release.
To make these steps easier, you can use the [`changelog`](https://github.com/cucumber/changelog) tool.

1. Make sure the CI is passing
1. Decide what the next version number should be
   * Look at `CHANGELOG.md` to see what has changed since the last relesase
   * Use [semver](https://semver.org/) to pick a version for the next release.
     ```
     export next_release=x.y.z
     ```
1. Modify the changelog:
   ```
   changelog release $next_release -o CHANGELOG.md
   # You may have to manually fix the links at the bottom due to a bug in the changelog command
   ```
   * If you don't have `changelog` installed, do it manually:
     * Under `[Unreleased]` at the top, add a new `[${version}] - ${YYYY-mm-dd}` header
     * Add a new `[${version}]` link at the bottom
     * Update the `[Unreleased]` link at the bottom
1. Update the version numbers in package descriptors:
   * `java/pom.xml` (keep the `-SNAPSHOT` suffix)
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

1. Push to a new `release/*` branch to trigger the [`release-*` workflows](https://github.com/cucumber/cucumber-expressions/actions)
   ```
   git push origin main:release/v$next_release
   ```
1. Wait until the `release-*` workflows in GitHub Actions have passed
1. Rerun individual workflows if they fail
1. Consider announcing the release on Slack/Twitter/Blog
