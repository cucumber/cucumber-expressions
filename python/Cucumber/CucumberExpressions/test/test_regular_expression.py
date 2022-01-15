import os
from typing import Optional

import pytest

from Cucumber.CucumberExpressions.parameter_type_registry import ParameterTypeRegistry
from Cucumber.CucumberExpressions.regular_expression import RegularExpression
from Cucumber.CucumberExpressions.definitions import TESTDATA_ROOT_DIR


def get_expectation_yamls():
    YAML_DIR = os.path.join(TESTDATA_ROOT_DIR, "regular-expression", "matching")
    return [
        os.path.join(YAML_DIR, file)
        for file in os.listdir(YAML_DIR)
        if file.endswith(".yaml")
    ]


class TestRegularExpression:
    @pytest.mark.parametrize("load_test_yamls", get_expectation_yamls(), indirect=True)
    def test_path_match(self, load_test_yamls: dict):
        expectation = load_test_yamls
        parameter_registry = ParameterTypeRegistry()
        expression = RegularExpression(expectation["expression"], parameter_registry)
        matches = expression.match(expectation["text"])
        values = [m.value for m in matches]
        assert values == expectation["expected_args"]

    def test_does_not_transform_by_default(self):
        assert self._match(r"(\d\d)", "22") == ["22"]

    def test_does_not_transform_anonymous(self):
        assert self._match(r"(.*)", "22") == ["22"]

    def test_transforms_negative_int(self):
        assert self._match(r"(-?\d+)", "-22") == [-22]

    def test_transforms_positive_int(self):
        assert self._match(r"(-?\d+)", "22") == [22]

    def test_returns_none_when_there_is_no_match(self):
        assert self._match(r"hello", "world") is None

    def test_matches_empty_string_when_there_is_an_empty_string_match(self):
        assert self._match(r'^The value equals "([^"]*)"$', 'The value equals ""') == [
            ""
        ]

    def test_matches_nested_capture_group_without_match(self):
        assert self._match(r'^a user( named "([^"]*)")?$', "a user") == [None]

    def test_matches_nested_capture_group_with_match(self):
        assert self._match(
            r'^a user( named "([^"]*)")?$', 'a user named "Charlie"'
        ) == ["Charlie"]

    def test_ignores_non_capturing_group(self):
        assert (
            self._match(
                r"(\S+) ?(can|cannot) (?:delete|cancel) the (\d+)(?:st|nd|rd|th) (attachment|slide) ?(?:upload)?",
                "I can cancel the 1st slide upload",
            )
            == ["I", "can", 1, "slide"]
        )

    @staticmethod
    def _match(expression: str, text: str) -> Optional[list[str]]:
        regular_expression = RegularExpression(expression, ParameterTypeRegistry())
        arguments = regular_expression.match(text)
        if not arguments:
            return None
        return [arg.value for arg in arguments]
