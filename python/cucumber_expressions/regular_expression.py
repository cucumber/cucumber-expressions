import re
from typing import Optional

from cucumber_expressions.argument import Argument
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.tree_regexp import TreeRegexp


class RegularExpression:
    def __init__(
        self, expression_regexp, parameter_type_registry: ParameterTypeRegistry
    ):
        self.expression_regexp = re.compile(expression_regexp)
        self.parameter_type_registry = parameter_type_registry
        self.tree_regexp: TreeRegexp = TreeRegexp(self.expression_regexp)

    """
     * Creates a new instance. Use this when the transform types are not known in advance,
     * and should be determined by the regular expression's capture groups. Use this with
     * dynamically typed languages.
     *
     * @param expressionRegexp      the regular expression to use
     * @param parameterTypeRegistry used to look up parameter types
     """

    def match(self, text) -> Optional[list[Argument]]:
        parameter_types = []
        for group_builder in self.tree_regexp.group_builder.children:
            parameter_type_regexp = group_builder.source
            _possible_regexp = self.parameter_type_registry.lookup_by_regexp(
                parameter_type_regexp, self.expression_regexp, text
            )
            if _possible_regexp:
                parameter_types.append(_possible_regexp)
            else:
                from cucumber_expressions.parameter_type import ParameterType

                parameter_types.append(
                    ParameterType(
                        None, parameter_type_regexp, str, lambda *s: s[0], False, False
                    )
                )
        return Argument.build(self.tree_regexp, text, parameter_types)

    @property
    def regexp(self):
        return self.expression_regexp.pattern

    def __str__(self):
        return self.regexp
