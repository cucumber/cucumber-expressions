import re
from collections.abc import Generator
from typing import Optional, Union

from cucumber_expressions.argument import Argument
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.tree_regexp import TreeRegexp

NAMED_CAPTURE_GROUP_REGEX = re.compile(r"\?P<([^>]+)>")


class RegularExpression:
    """Creates a new instance. Use this when the transform types are not known in advance,
    and should be determined by the regular expression's capture groups. Use this with
    dynamically typed languages."""

    def __init__(
        self,
        expression_regexp: Union[re.Pattern, str],
        parameter_type_registry: ParameterTypeRegistry,
    ):
        """Creates a new instance. Use this when the transform types are not known in advance,
        and should be determined by the regular expression's capture groups. Use this with
        dynamically typed languages.
        :param expression_regexp: the regular expression to use
        :type expression_regexp: Pattern
        :param parameter_type_registry: used to look up parameter types
        :type parameter_type_registry: ParameterTypeRegistry
        """
        self.expression_regexp = re.compile(expression_regexp)
        self.parameter_type_registry = parameter_type_registry
        self.tree_regexp: TreeRegexp = TreeRegexp(self.expression_regexp.pattern)

    def match(self, text) -> Optional[list[Argument]]:
        # Convert the generator to a list before passing it to Argument.build
        parameter_types_and_names = list(
            (parameter_type, capture_name)
            for parameter_type, capture_name in self.generate_parameter_types(text)
        )
        return Argument.build(self.tree_regexp, text, parameter_types_and_names)

    @staticmethod
    def _remove_named_groups(pattern: str) -> str:
        """
        Remove named capture groups from the regex pattern using precompiled regex.
        """
        return NAMED_CAPTURE_GROUP_REGEX.sub("", pattern)

    def _process_capture_group(self, group_source: str):
        """
        Check if the capture group is named and extract the name.
        If it's a named capture group, return the name and the modified regex.
        """
        # Check for named capture group using the precompiled regex
        match = NAMED_CAPTURE_GROUP_REGEX.match(group_source)

        if match:
            # Extract the name of the capture group
            capture_group_name = match.group(1)
            # Remove the named group part using the precompiled regex
            cleaned_pattern = self._remove_named_groups(group_source)
            return capture_group_name, cleaned_pattern
        else:
            # No named group, just return the original pattern
            return None, group_source

    def generate_parameter_types(
        self, text
    ) -> Generator[tuple[ParameterType, Optional[str]]]:
        for group_builder in self.tree_regexp.group_builder.children:
            # Extract the raw source for the group
            parameter_type_regexp = group_builder.source

            # Process the capture group (check if it's named and clean the pattern)
            capture_name, cleaned_pattern = self._process_capture_group(
                parameter_type_regexp
            )

            # Lookup the parameter type using the stripped capture group
            possible_regexp = self.parameter_type_registry.lookup_by_regexp(
                cleaned_pattern, self.expression_regexp, text
            )

            parameter_type = possible_regexp or ParameterType(
                capture_name, cleaned_pattern, str, lambda *s: s[0], False, False
            )
            yield parameter_type, capture_name

    @property
    def regexp(self):
        return self.expression_regexp.pattern
