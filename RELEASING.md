See [.github/RELEASING](https://github.com/cucumber/.github/blob/main/RELEASING.md).

Before making a release, manually rebuild the *try cucumber expressions playground*:

    cd javascript
    npm install
    npm run build:try

Run it locally:

    npm run build:try:serve

Poke around and manually verify that it's not broken.
