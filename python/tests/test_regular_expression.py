from pathlib import Path
from typing import Optional, List

from tests.definitions import TESTDATA_ROOT_DIR

import pytest

from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.regular_expression import RegularExpression


def get_expectation_yamls():
    yaml_dir = Path(TESTDATA_ROOT_DIR) / "regular-expression" / "matching"
    return [
        Path(yaml_dir) / file
        for file in Path(yaml_dir).iterdir()
        if file.suffix == ".yaml"
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

    def test_ignores_non_capturing_groups(self):
        assert self._match(
            r"(\S+) ?(can|cannot) (?:delete|cancel) the (\d+)(?:st|nd|rd|th) (attachment|slide) ?(?:upload)?",
            "I can cancel the 1st slide upload",
        ) == ["I", "can", 1, "slide"]

    def test_matches_capture_group_nested_in_optional_one(self):
        regexp = r"^a (pre-commercial transaction |pre buyer fee model )?purchase(?: for \$(\d+))?$"
        assert self._match(regexp, "a purchase") == [None, None]
        assert self._match(regexp, "a purchase for $33") == [None, 33]
        assert self._match(regexp, "a pre buyer fee model purchase") == [
            "pre buyer fee model ",
            None,
        ]

    def test_works_with_escaped_parentheses(self):
        assert self._match(r"Across the line\(s\)", "Across the line(s)") == []

    def test_exposes_regexp(self):
        regexp = r"I have (\d+) cukes? in my (\+) now"
        expression = RegularExpression(regexp, ParameterTypeRegistry())
        assert expression.regexp == regexp

    @staticmethod
    def _match(expression: str, text: str) -> Optional[List[str]]:
        regular_expression = RegularExpression(expression, ParameterTypeRegistry())
        arguments = regular_expression.match(text)
        return arguments and [arg.value for arg in arguments]
