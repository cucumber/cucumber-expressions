from decimal import Decimal
from pathlib import Path

from tests.definitions import TESTDATA_ROOT_DIR

import pytest

from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry


def get_expectation_yamls():
    yaml_dir = Path(TESTDATA_ROOT_DIR) / "cucumber-expression" / "matching"
    return [
        Path(yaml_dir) / file
        for file in Path(yaml_dir).iterdir()
        if file.suffix == ".yaml"
    ]


def match(
    expression: str,
    match_text: str,
    parameter_registry: ParameterTypeRegistry = ParameterTypeRegistry(),
):
    cucumber_expression = CucumberExpression(expression, parameter_registry)
    matches = cucumber_expression.match(match_text)

    def transform_value(value):
        if isinstance(value, int):
            return str(value) if value.bit_length() > 64 else value
        if isinstance(value, Decimal):
            return str(value)
        return value

    return matches and [transform_value(arg.value) for arg in matches]


class TestCucumberExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_cucumber_expression_matches(self, load_test_yamls: dict):
        expectation = load_test_yamls
        if "exception" in expectation:
            with pytest.raises(Exception) as excinfo:
                match(expectation["expression"], expectation.get("text", ""))
            assert excinfo.value.args[0] == expectation["exception"]
        else:
            values = match(expectation["expression"], expectation["text"])
            assert values == expectation["expected_args"]

    def test_documents_match_arguments(self):
        values = match("I have {int} cuke(s)", "I have 7 cukes")
        assert values[0] == 7

    def test_matches_float(self):
        assert match("{float}", "") is None
        assert match("{float}", ".") is None
        assert match("{float}", ",") is None
        assert match("{float}", "-") is None
        assert match("{float}", "E") is None
        assert match("{float}", "1,") is None
        assert match("{float}", ",1") is None
        assert match("{float}", "1.") is None

        assert match("{float}", "1") == [1]
        assert match("{float}", "-1") == [-1]
        assert match("{float}", "1.1") == [1.1]
        assert match("{float}", "1,000") is None
        assert match("{float}", "1,000,0") is None
        assert match("{float}", "1,000.1") is None
        assert match("{float}", "1,000,10") is None
        assert match("{float}", "1,0.1") is None
        assert match("{float}", "1,000,000.1") is None
        assert match("{float}", "-1.1") == [-1.1]

        assert match("{float}", ".1") == [0.1]
        assert match("{float}", "-.1") == [-0.1]
        assert match("{float}", "-.1000001") == [-0.1000001]
        assert match("{float}", "1E1") == [10.0]
        assert match("{float}", ".1E1") == [1]
        assert match("{float}", "E1") is None
        assert match("{float}", "-.1E-1") == [-0.01]
        assert match("{float}", "-.1E-2") == [-0.001]
        assert match("{float}", "-.1E+1") == [-1]
        assert match("{float}", "-.1E+2") == [-10]
        assert match("{float}", "-.1E1") == [-1]
        assert match("{float}", "-.1E2") == [-10]

    def test_float_with_zero(self):
        assert match("{float}", "0") == [0.0]

    def test_matches_anonymous(self):
        assert match("{}", "0.22") == ["0.22"]

    def test_exposes_source(self):
        expr = "I have {int} cuke(s)"
        assert CucumberExpression(expr, ParameterTypeRegistry()).source == expr

    def test_unmatched_optional_groups_have_undefined_values(self):
        parameter_type_registry = ParameterTypeRegistry()
        parameter_type_registry.define_parameter_type(
            ParameterType(
                "textAndOrNumber",
                r"([A-Z]+)?(?: )?([0-9]+)?",
                object,
                lambda s1, s2: [s1, s2],
                False,
                True,
            )
        )

        assert match("{textAndOrNumber}", "TLA", parameter_type_registry)[0] == [
            "TLA",
            None,
        ]
        assert match("{textAndOrNumber}", "123", parameter_type_registry)[0] == [
            None,
            "123",
        ]
