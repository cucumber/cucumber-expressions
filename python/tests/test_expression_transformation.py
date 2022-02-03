from pathlib import Path

import pytest

from tests.definitions import TESTDATA_ROOT_DIR

from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry


def get_expectation_yamls():
    yaml_dir = Path(TESTDATA_ROOT_DIR) / "cucumber-expression" / "transformation"
    return [
        Path(yaml_dir) / file
        for file in Path(yaml_dir).iterdir()
        if file.suffix == ".yaml"
    ]


class TestCucumberExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_cucumber_expression_transforms(self, load_test_yamls: dict):
        expectation = load_test_yamls
        parameter_registry = ParameterTypeRegistry()
        expression = CucumberExpression(expectation["expression"], parameter_registry)
        assert expression.regexp == expectation["expected_regex"]
