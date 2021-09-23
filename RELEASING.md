# Releasing

The steps below are currently manual, but they can be automated.
If we do automate it, we should do this in a way that it can be
maintained in one place and used easily in any `cucumber/*` repo.

1. Make sure the CI badges in `README.md` indicate passing 
1. Decide what the next version number should be
  * Look at `CHANGELOG.md`
  * Consult [semver](https://semver.org/)
1. Update `CHANGELOG.md`
  * Under `[Unreleased]` at the top, add a new `[${version}] - ${YYYY-mm-dd}` header
  * Add a new `[${version}]` link at the bottom
  * Update the `[Unreleased]` link at the bottom
1. Update the version numbers in:
  * `java/pom.xml` (`${version}-SNAPSHOT`)
  * `javascript/package.json`
  * `ruby/VERSION`
1. Run `git commit -am "Release ${version}"`
1. Run `git push`
1. Run `git checkout -b release/v${version} && git push`
  * This will trigger the `.github/workflows/release-*.yml` workflows
1. Monitor the `release-*` workflows in GitHub Actions
1. Rerun individual workflows if they fail
1. Consider announcing the release on Slack/Twitter/Blog
