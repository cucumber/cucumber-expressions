# Tests

The test suite uses `pytest` as its testing Framework.


## Preparing to run the tests

Ensure that you have `python` installed that you have setup virtual environment for this tutorial by installing `python3-venv` package.

Create a Python environment.

``` python
python3 -m venv <env_name>
```

Install the needed modules i.e `pytest`, `pytest` and so forth using the `requirements.txt` file (instructions from project root dir)

``` python
pip3 install -r tests/requirements.txt
```

## Running the tests

`pytest` automatically picks up files in the currect/sub directory that have the prefix or suffix of `test_*.py` or `*_test.py`, respectively, unless stated explicitly which files to run. And, it requires test function names to start with `test` otherwise it won't treat those functions as test functions and this applies to classes.

To run all tests:

``` python
pytest ./test -v # execute all tests in verbose mode
pytest <filename> -v # to execute specific test file
```

