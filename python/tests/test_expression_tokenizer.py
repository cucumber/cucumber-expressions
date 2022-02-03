from pathlib import Path

from tests.definitions import TESTDATA_ROOT_DIR

import pytest

from cucumber_expressions.expression_tokenizer import (
    CucumberExpressionTokenizer,
)
from cucumber_expressions.errors import (
    CantEscape,
    TheEndOfLineCannotBeEscaped,
)


def get_expectation_yamls():
    yaml_dir = Path(TESTDATA_ROOT_DIR) / "cucumber-expression" / "tokenizer"
    return [
        Path(yaml_dir) / file
        for file in Path(yaml_dir).iterdir()
        if file.suffix == ".yaml"
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
