import pytest as pytest
import yaml


@pytest.fixture
def load_test_yamls(request) -> dict:
    with open(request.param) as stream:
        yield yaml.safe_load(stream)
