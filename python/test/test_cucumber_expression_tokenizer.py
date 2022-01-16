import os

import pytest

from cucumber_expressions.cucumber_expression_tokenizer import (
    CucumberExpressionTokenizer,
)
from test.definitions import TESTDATA_ROOT_DIR
from cucumber_expressions.errors import (
    CantEscape,
    TheEndOfLineCannotBeEscaped,
)


def get_expectation_yamls():
    YAML_DIR = os.path.join(TESTDATA_ROOT_DIR, "cucumber-expression", "tokenizer")
    return [
        os.path.join(YAML_DIR, file)
        for file in os.listdir(YAML_DIR)
        if file.endswith(".yaml")
    ]


class TestCucumberExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_cucumber_expression_tokenizes(self, load_test_yamls: dict):
        expectation = load_test_yamls
        tokenizer = CucumberExpressionTokenizer()
        if "exception" in expectation:
            with pytest.raises((CantEscape, TheEndOfLineCannotBeEscaped)) as excinfo:
                tokenizer.tokenize(expectation["expression"])
            assert excinfo.value.args[0] == expectation["exception"]
        else:
            tokens = tokenizer.tokenize(expectation["expression"], to_json=True)
            assert tokens == expectation["expected_tokens"]
