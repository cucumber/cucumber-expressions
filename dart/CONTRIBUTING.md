# Contributing to Cucumber Expressions for Dart

## Setup

Install the supported [Dart SDK](https://dart.dev/get-dart) and fetch the
package dependencies from this directory:

```sh
dart pub get
```

## Verification

Run these commands from the `dart/` directory before opening a pull request:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart pub publish --dry-run
```
