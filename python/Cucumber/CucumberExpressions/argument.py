from __future__ import annotations

from typing import Optional

from Cucumber.CucumberExpressions.group import Group
from Cucumber.CucumberExpressions.parameter_type import ParameterType
from Cucumber.CucumberExpressions.tree_regexp import TreeRegexp
from Cucumber.CucumberExpressions.exceptions.errors import CucumberExpressionError


class Argument:
    def __init__(self, group, parameter_type):
        self._group: Group = group
        self.parameter_type: ParameterType = parameter_type
        self._value = None

    @staticmethod
    def build(
        tree_regexp: TreeRegexp, text: str, parameter_types: list
    ) -> Optional[list[Argument]]:
        group = tree_regexp.match(text)
        if not group:
            return None

        arg_groups = group.children

        if len(arg_groups) != len(parameter_types):
            raise CucumberExpressionError(
                f"Group has {len(arg_groups)} capture groups, but there were {len(parameter_types)} parameter types"
            )

        return [
            Argument(arg_group, parameter_type)
            for parameter_type, arg_group in zip(parameter_types, arg_groups)
        ]

    @property
    def value(self):
        group_values = self.group.values
        return self.parameter_type.transform(group_values)

    @property
    def group(self):
        return self._group
