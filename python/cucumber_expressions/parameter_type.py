from __future__ import annotations

import re

from cucumber_expressions.errors import CucumberExpressionError

ILLEGAL_PARAMETER_NAME_PATTERN = r"([\[\]()$.|?*+])"
UNESCAPE_PATTERN = r"(\\([\[$.|?*+\]]))"


class ParameterType:
    def check_parameter_type_name(self, type_name):
        if not self.is_valid_parameter_type_name(type_name):
            raise CucumberExpressionError(
                f"Illegal character in parameter name {type_name}. Parameter names may not contain '[]()$.|?*+'"
            )

    @staticmethod
    def is_valid_parameter_type_name(type_name):
        return not bool(re.compile(ILLEGAL_PARAMETER_NAME_PATTERN).match(type_name))

    def transform(self, group_values: list[str]):
        return self.transformer(*group_values)

    @staticmethod
    def compare(pt1: ParameterType, pt2: ParameterType):
        if pt1.prefer_for_regexp_match and not pt2.prefer_for_regexp_match:
            return -1
        if pt2.prefer_for_regexp_match and not pt1.prefer_for_regexp_match:
            return 1
        _a_name = len(pt1.name or "")
        _b_name = len(pt2.name or "")

        if _a_name < _b_name:
            return -1
        elif _a_name > _b_name:
            return 1
        else:
            return 0

    # Create a new Parameter
    #
    # @param name the name of the parameter type
    # @param regexp [Array] list of regexps for capture groups. A single regexp can also be used
    # @param type the return type of the transformed
    # @param transformer lambda that transforms a String to (possibly) another type
    # @param use_for_snippets true if this should be used for snippet generation
    # @param prefer_for_regexp_match true if this should be preferred over similar types
    #
    def __init__(
        self,
        name,
        regexp,
        param_type,
        transformer,
        use_for_snippets,
        prefer_for_regexp_match,
    ):
        self.name = name
        if self.name:
            self.check_parameter_type_name(self.name)
        self.regexp = regexp
        self.param_type = param_type
        self.transformer = transformer
        self._use_for_snippets = use_for_snippets
        self._prefer_for_regexp_match = prefer_for_regexp_match
        self.regexps = self.string_array(self.regexp)

    @property
    def prefer_for_regexp_match(self):
        return self._prefer_for_regexp_match

    @prefer_for_regexp_match.setter
    def prefer_for_regexp_match(self, value: bool):
        self._prefer_for_regexp_match = value

    @property
    def use_for_snippets(self):
        return self._use_for_snippets

    @use_for_snippets.setter
    def use_for_snippets(self, value: bool):
        self._use_for_snippets = value

    @staticmethod
    def string_array(regexps: str):
        return regexps if isinstance(regexps, list) else [regexps]
