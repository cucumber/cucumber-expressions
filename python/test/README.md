# Tests

The test suite uses `pytest` as its testing Framework.


## Preparing to run the tests

Ensure that you have `python` installed that you have set up virtual environment by installing `python3-venv` package.

Create a Python environment.

``` python
python3 -m venv <env_name>
```

Install the needed dependency modules by using the `requirements.txt` file (instructions from project root dir)

``` python
pip3 install -r tests/requirements.txt
```

## Running the tests

`pytest` automatically picks up files in the current directory or any subdirectories that have the prefix or suffix of `test_*.py`.
Test function names must start with `test*`.
Test class names must start with `Test*`.

To run all tests:

``` python
pytest # execute all tests
pytest -v # execute all tests in verbose mode
pytest <filename> -v # to execute specific test file
```

