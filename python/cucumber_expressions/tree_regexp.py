import re
from typing import Pattern, Union, Optional, List

from cucumber_expressions.ast import EscapeCharacters
from cucumber_expressions.group import Group
from cucumber_expressions.group_builder import GroupBuilder


class TreeRegexp:
    def __init__(self, regexp: Union[Pattern[str], str]):
        self.regexp = regexp if isinstance(regexp, Pattern) else re.compile(regexp)
        self.group_builder = self.create_group_builder(self.regexp)

    def match(self, string: str) -> Optional[Group]:
        matches = self.regexp.match(string)
        if not matches:
            return None
        group_indices = range(len(matches.groups()) + 1)
        group_names_map = {v: k for k, v in self.regexp.groupindex.items()}
        return self.group_builder.build(matches, iter(group_indices), group_names_map)

    def create_group_builder(self, regexp):
        source = regexp.pattern
        stack: List[GroupBuilder] = [GroupBuilder()]
        group_start_stack = []
        escaping: bool = False
        char_class: bool = False

        for index, char in enumerate(source):
            if char == "[" and not escaping:
                char_class = True
            elif char == "]" and not escaping:
                char_class = False
            elif char == "(" and not escaping and not char_class:
                group_start_stack.append(index)
                group_builder = GroupBuilder()
                if self.is_non_capturing(source, index):
                    group_builder.capturing = False
                elif self.is_named_group(source, index):
                    group_builder.capturing = True
                    # Handle named groups here (mark their names)
                    group_name = self.extract_named_group_name(source, index)
                    group_builder.name = group_name
                stack.append(group_builder)
            elif char == ")" and not escaping and not char_class:
                group_builder = stack.pop()
                if not group_builder:
                    raise Exception("Empty stack!")
                group_start = group_start_stack.pop()
                group_start = group_start or 0
                if group_builder.capturing:
                    group_builder.source = source[(group_start + 1) : index]
                    stack[-1].add(group_builder)
                else:
                    group_builder.move_children_to(stack[-1])
            escaping = not escaping and char == EscapeCharacters.ESCAPE_CHARACTER.value
        return stack.pop()

    @staticmethod
    def is_named_group(source: str, index: int) -> bool:
        """
        Check if the group at the given index is a named capturing group, e.g. (?P<name>...).
        """
        return source[index + 1 : index + 3] == "P<" and source[index + 3] != "?"

    @staticmethod
    def extract_named_group_name(source: str, index: int) -> str:
        """
        Extract the name of a named capturing group, e.g., (?P<name>...) returns "name".
        """
        group_name_start = index + 3
        group_name_end = source.find(">", group_name_start)
        return source[group_name_start:group_name_end]

    @staticmethod
    def is_non_capturing(source: str, index: int) -> bool:
        # Check if it's a non-capturing group like (?:...)
        if source[index + 1] != "?":
            return False

        # If it's a named group (e.g., (?P<name>...)), it's still a capturing group
        if source[index + 2] == "P" and source[index + 3] == "<":
            return False  # Named capturing group, should return False (it's capturing)

        # Otherwise, it's a non-capturing group (e.g., (?:...), (?=...), etc.)
        return True
