import os

from tests.definitions import TESTDATA_ROOT_DIR

import pytest

from cucumber_expressions.cucumber_expression_parser import (
    CucumberExpressionParser,
)


def get_expectation_yamls():
    yaml_dir = os.path.join(TESTDATA_ROOT_DIR, "cucumber-expression", "parser")
    return [
        os.path.join(yaml_dir, file)
        for file in os.listdir(yaml_dir)
        if file.endswith(".yaml")
    ]


class TestCucumberExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_cucumber_expression_matches(self, load_test_yamls: dict):
        expectation = load_test_yamls
        parser = CucumberExpressionParser()
        if "exception" in expectation:
            with pytest.raises(Exception) as excinfo:
                parser.parse(expectation["expression"])
            assert excinfo.value.args[0] == expectation["exception"]
        else:
            node = parser.parse(expectation["expression"])
            assert node.to_json() == expectation["expected_ast"]
