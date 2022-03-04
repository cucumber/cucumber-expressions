# Cucumber Expressions for Python

[The main docs are here](https://github.com/cucumber/cucumber-expressions#readme).

## Build system

This project uses [Poetry](https://python-poetry.org/) as its build system.
In order to develop on this project, please install Poetry as per your system's instructions on the link above.

## Tests

The test suite uses `pytest` as its testing Framework.


### Preparing to run the tests

In order to set up your dev environment, run the following command from this project's directory:

``` python
poetry install
```
It will install all package and development requirements, and once that is done it will do a dev-install of the source code.

You only need to run it once, code changes will propagate directly and do not require running the install again.


### Running the tests

`pytest` automatically picks up files in the current directory or any subdirectories that have the prefix or suffix of `test_*.py`.
Test function names must start with `test*`.
Test class names must start with `Test*`.

To run all tests:

``` python
poetry run pytest
```

