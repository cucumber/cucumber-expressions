import re

from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.regular_expression import RegularExpression

CURLY_BRACKET_PATTERN = re.compile(r"{(.*?)}")
INVALID_CURLY_PATTERN = re.compile(r"^\d+(?:,\d+)?$")


class ExpressionFactory:
    def __init__(
        self, parameter_type_registry: ParameterTypeRegistry = ParameterTypeRegistry()
    ):
        self.parameter_type_registry = parameter_type_registry

    @staticmethod
    def _has_curly_brackets(string: str) -> bool:
        return "{" in string and "}" in string

    @staticmethod
    def _extract_text_in_curly_brackets(string: str) -> list:
        return CURLY_BRACKET_PATTERN.findall(string)

    def is_cucumber_expression(self, expression_string: str):
        if not self._has_curly_brackets(expression_string):
            return False
        bracket_texts = self._extract_text_in_curly_brackets(expression_string)
        # Check if any match does not contain an integer or an integer and a comma
        for text in bracket_texts:
            # Check if the match is a regex pattern (matches integer or integer-comma pattern)
            if INVALID_CURLY_PATTERN.match(text):
                return False  # Found a form of curly bracket
        return True  # All curly brackets are valid

    def create_expression(self, expression_string: str):
        if self.is_cucumber_expression(expression_string):
            return CucumberExpression(expression_string, self.parameter_type_registry)
        return RegularExpression(expression_string, self.parameter_type_registry)
