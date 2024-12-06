from typing import Optional, List

from cucumber_expressions.argument import Argument
from cucumber_expressions.ast import Node, NodeType
from cucumber_expressions.expression_parser import CucumberExpressionParser
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.tree_regexp import TreeRegexp
from cucumber_expressions.errors import (
    ParameterIsNotAllowedInOptional,
    OptionalIsNotAllowedInOptional,
    OptionalMayNotBeEmpty,
    AlternativeMayNotBeEmpty,
    AlternativeMayNotExclusivelyContainOptionals,
    UndefinedParameterTypeError,
)

ESCAPE_PATTERN = rb"([\\^\[({$.|?*+})\]])"


class CucumberExpression:
    def __init__(self, expression: str, parameter_type_registry: ParameterTypeRegistry):
        self.expression = expression
        self.parameter_type_registry = parameter_type_registry
        self.parameter_types_and_names: List[tuple[ParameterType, Optional[str]]] = []
        self.tree_regexp = TreeRegexp(
            self.rewrite_to_regex(CucumberExpressionParser().parse(self.expression))
        )

    def match(self, text: str) -> Optional[List[Argument]]:
        return Argument.build(self.tree_regexp, text, self.parameter_types_and_names)

    @property
    def source(self):
        return self.expression

    @property
    def regexp(self) -> str:
        return self.tree_regexp.regexp.pattern

    def rewrite_to_regex(self, node: Node):
        if node.ast_type == NodeType.TEXT:
            return self.escape_regex(node.text)
        if node.ast_type == NodeType.OPTIONAL:
            return self.rewrite_optional(node)
        if node.ast_type == NodeType.ALTERNATION:
            return self.rewrite_alternation(node)
        if node.ast_type == NodeType.ALTERNATIVE:
            return self.rewrite_alternative(node)
        if node.ast_type == NodeType.PARAMETER:
            return self.rewrite_parameter(node)
        if node.ast_type == NodeType.EXPRESSION:
            return self.rewrite_expression(node)
        # Can't happen as long as the switch case is exhaustive
        raise Exception(node.ast_type)

    @staticmethod
    def escape_regex(expression) -> str:
        return expression.translate({i: "\\" + chr(i) for i in ESCAPE_PATTERN})

    def rewrite_optional(self, node: Node) -> str:
        if self.get_possible_node_with_parameters(node):
            raise ParameterIsNotAllowedInOptional(
                self.get_possible_node_with_parameters(node), self.expression
            )
        if self.get_possible_node_with_optionals(node):
            raise OptionalIsNotAllowedInOptional(
                self.get_possible_node_with_optionals(node), self.expression
            )
        if self.are_nodes_empty(node):
            raise OptionalMayNotBeEmpty(node, self.expression)
        regex = "".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return rf"(?:{regex})?"

    def rewrite_alternation(self, node: Node) -> str:
        for alternative in node.nodes:
            if not alternative.nodes:
                raise AlternativeMayNotBeEmpty(alternative, self.expression)
            if self.are_nodes_empty(alternative):
                raise AlternativeMayNotExclusivelyContainOptionals(
                    alternative, self.expression
                )
        regex = "|".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return f"(?:{regex})"

    def rewrite_alternative(self, node: Node):
        return "".join([self.rewrite_to_regex(_node) for _node in node.nodes])

    def rewrite_parameter(self, node: Node) -> str:
        name = node.text
        group_name, parameter_type = self.parse_parameter_name(name)

        if not parameter_type:
            raise UndefinedParameterTypeError(node, self.expression, name)

        self.parameter_types_and_names.append((parameter_type, group_name))

        regexps = parameter_type.regexps
        if len(regexps) == 1:
            return rf"({regexps[0]})"
        return rf"((?:{')|(?:'.join(regexps)}))"

    def parse_parameter_name(
        self, name: str
    ) -> tuple[Optional[str], Optional[ParameterType]]:
        """Helper function to parse the parameter name and return group_name and parameter_type."""
        if ":" in name:
            group_name, parameter_type_name = name.split(":")
            parameter_type = self.parameter_type_registry.lookup_by_type_name(
                parameter_type_name
            )
        else:
            group_name = None
            parameter_type = self.parameter_type_registry.lookup_by_type_name(name)
        return group_name, parameter_type

    def rewrite_expression(self, node: Node):
        regex = "".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return rf"^{regex}$"

    def are_nodes_empty(self, node: Node) -> bool:
        return not any(self.get_nodes_with_ast_type(node, NodeType.TEXT))

    def get_possible_node_with_parameters(self, node: Node) -> Optional[Node]:
        results = self.get_nodes_with_ast_type(node, NodeType.PARAMETER)
        return results[0] if results else None

    def get_possible_node_with_optionals(self, node: Node) -> Optional[Node]:
        results = self.get_nodes_with_ast_type(node, NodeType.OPTIONAL)
        return results[0] if results else None

    @staticmethod
    def get_nodes_with_ast_type(node: Node, ast_type: NodeType) -> List[Node]:
        return [ast_node for ast_node in node.nodes if ast_node.ast_type == ast_type]
