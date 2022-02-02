import pytest
import yaml


@pytest.fixture
def load_test_yamls(request) -> dict:
    """Opens a given test yaml file"""
    with open(request.param, encoding="UTF-8") as stream:
        yield yaml.safe_load(stream)
