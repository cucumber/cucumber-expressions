from decimal import Decimal
from pathlib import Path
from typing import Optional, Any, Tuple

from tests.definitions import TESTDATA_ROOT_DIR

import pytest

from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry


def get_expectation_yamls():
    yaml_dir = Path(TESTDATA_ROOT_DIR) / "cucumber-expression" / "matching"
    return [yaml_dir / file for file in yaml_dir.iterdir() if file.suffix == ".yaml"]


def match(
    expression: str,
    match_text: str,
    parameter_registry: ParameterTypeRegistry = ParameterTypeRegistry(),
) -> Optional[Tuple[Any, str]]:
    cucumber_expression = CucumberExpression(expression, parameter_registry)
    matches = cucumber_expression.match(match_text)

    def transform_value(value):
        if isinstance(value, int):
            return str(value) if value.bit_length() > 64 else value
        if isinstance(value, Decimal):
            return str(value)
        return value

    return matches and [(transform_value(arg.value), arg.name) for arg in matches]


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
            actual_result = None if values is None else [value[0] for value in values]
            assert actual_result == expectation["expected_args"]

    def test_documents_match_arguments(self):
        values = match("I have {int} cuke(s)", "I have 7 cukes")
        assert values[0] == (7, None)

    def test_documents_match_arguments_with_names(self):
        values = match("I have {cuke_count:int} cuke(s)", "I have 7 cukes")
        assert values[0] == (7, "cuke_count")

    def test_matches_float(self):
        assert match("{float}", "") is None
        assert match("{float}", ".") is None
        assert match("{float}", ",") is None
        assert match("{float}", "-") is None
        assert match("{float}", "E") is None
        assert match("{float}", "1,") is None
        assert match("{float}", ",1") is None
        assert match("{float}", "1.") is None

        assert match("{float}", "1") == [(1, None)]
        assert match("{float}", "-1") == [(-1, None)]
        assert match("{float}", "1.1") == [(1.1, None)]
        assert match("{float}", "1,000") is None
        assert match("{float}", "1,000,0") is None
        assert match("{float}", "1,000.1") is None
        assert match("{float}", "1,000,10") is None
        assert match("{float}", "1,0.1") is None
        assert match("{float}", "1,000,000.1") is None
        assert match("{float}", "-1.1") == [(-1.1, None)]

        assert match("{float}", ".1") == [(0.1, None)]
        assert match("{float}", "-.1") == [(-0.1, None)]
        assert match("{float}", "-.1000001") == [(-0.1000001, None)]
        assert match("{float}", "1E1") == [(10.0, None)]
        assert match("{float}", ".1E1") == [(1, None)]
        assert match("{float}", "E1") is None
        assert match("{float}", "-.1E-1") == [(-0.01, None)]
        assert match("{float}", "-.1E-2") == [(-0.001, None)]
        assert match("{float}", "-.1E+1") == [(-1, None)]
        assert match("{float}", "-.1E+2") == [(-10, None)]
        assert match("{float}", "-.1E1") == [(-1, None)]
        assert match("{float}", "-.1E2") == [(-10, None)]

    def test_float_with_zero(self):
        assert match("{float}", "0") == [(0.0, None)]

    def test_matches_anonymous(self):
        assert match("{}", "0.22") == [("0.22", None)]

    def test_exposes_source(self):
        expr = "I have {int} cuke(s)"
        assert CucumberExpression(expr, ParameterTypeRegistry()).source == expr

    def test_with_name_exposes_source(self):
        expr = "I have {cuke_count:int} cuke(s)"
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

        assert match("{textAndOrNumber}", "TLA", parameter_type_registry)[0] == (
            ["TLA", None],
            None,
        )
        assert match("{textAndOrNumber}", "123", parameter_type_registry)[0] == (
            [None, "123"],
            None,
        )
