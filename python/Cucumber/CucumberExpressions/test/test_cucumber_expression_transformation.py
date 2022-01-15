import os

import pytest

from Cucumber.CucumberExpressions.cucumber_expression import CucumberExpression
from Cucumber.CucumberExpressions.parameter_type_registry import ParameterTypeRegistry
from Cucumber.CucumberExpressions.definitions import TESTDATA_ROOT_DIR


def get_expectation_yamls():
    YAML_DIR = os.path.join(TESTDATA_ROOT_DIR, "cucumber-expression", "transformation")
    return [
        os.path.join(YAML_DIR, file)
        for file in os.listdir(YAML_DIR)
        if file.endswith(".yaml")
    ]


class TestCucumberExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_cucumber_expression_transforms(self, load_test_yamls: dict):
        expectation = load_test_yamls
        parameter_registry = ParameterTypeRegistry()
        expression = CucumberExpression(expectation["expression"], parameter_registry)
        assert expression.regexp == expectation["expected_regex"]
