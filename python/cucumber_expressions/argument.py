from __future__ import annotations

from typing import Optional, List

from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.tree_regexp import TreeRegexp, Group
from cucumber_expressions.errors import CucumberExpressionError


class Argument:
    def __init__(
        self, group: Group, parameter_type: ParameterType, name: Optional[str]
    ):
        self.group = group
        self.parameter_type = parameter_type
        self.name = name

    @staticmethod
    def build(
        tree_regexp: TreeRegexp,
        text: str,
        parameter_types_and_names: List[tuple[ParameterType, Optional[str]]],
    ) -> Optional[List[Argument]]:
        # Check if all elements in parameter_types_and_names are tuples
        for item in parameter_types_and_names:
            if not isinstance(item, tuple) or len(item) != 2:
                raise CucumberExpressionError(
                    f"Expected a tuple of (ParameterType, Optional[str]), but got {type(item)}: {item}"
                )

        match_group = tree_regexp.match(text)
        if not match_group:
            return None

        arg_groups = match_group.children

        if len(arg_groups) != len(parameter_types_and_names):
            param_count = len(parameter_types_and_names)
            raise CucumberExpressionError(
                f"Group has {len(arg_groups)} capture groups, but there were {param_count} parameter types/names"
            )

        return [
            Argument(arg_group, parameter_type, parameter_name)
            for (parameter_type, parameter_name), arg_group in zip(
                parameter_types_and_names, arg_groups
            )
        ]

    @property
    def value(self):
        return self.parameter_type.transform(self.group.values if self.group else None)
