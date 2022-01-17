from typing import Optional

from cucumber_expressions.argument import Argument
from cucumber_expressions.ast import Node, NodeType
from cucumber_expressions.cucumber_expression_parser import (
    CucumberExpressionParser,
)
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.tree_regexp import TreeRegexp
from cucumber_expressions.errors import (
    UndefinedParameterTypeError,
    ParameterIsNotAllowedInOptional,
    OptionalIsNotAllowedInOptional,
    OptionalMayNotBeEmpty,
    AlternativeMayNotBeEmpty,
    AlternativeMayNotExclusivelyContainOptionals,
)

ESCAPE_PATTERN = b"([\\^\[({$.|?*+})\]])"  # noqa W605


class CucumberExpression:
    def __init__(self, expression, parameter_type_registry):
        self.expression = expression
        self.parameter_type_registry = parameter_type_registry
        self.parameter_types: list[ParameterType] = []
        self.tree_regexp = TreeRegexp(
            self.rewrite_to_regex(CucumberExpressionParser().parse(self.expression))
        )

    def match(self, text: str) -> Optional[list[Argument]]:
        return Argument.build(self.tree_regexp, text, self.parameter_types)

    @property
    def source(self):
        return self.expression

    @property
    def regexp(self):
        return self.tree_regexp.regexp

    def __str__(self):
        self.source()

    def rewrite_to_regex(self, node: Node):
        if node.ast_type == NodeType.TEXT:
            return self.escape_regex(node.text)
        elif node.ast_type == NodeType.OPTIONAL:
            return self.rewrite_optional(node)
        elif node.ast_type == NodeType.ALTERNATION:
            return self.rewrite_alternation(node)
        elif node.ast_type == NodeType.ALTERNATIVE:
            return self.rewrite_alternative(node)
        elif node.ast_type == NodeType.PARAMETER:
            return self.rewrite_parameter(node)
        elif node.ast_type == NodeType.EXPRESSION:
            return self.rewrite_expression(node)
        else:
            # Can't happen as long as the switch case is exhaustive
            raise Exception(node.ast_type)

    @staticmethod
    def escape_regex(expression):
        return expression.translate({i: "\\" + chr(i) for i in ESCAPE_PATTERN})

    def rewrite_optional(self, node: Node):
        if _possible_node_with_params := self.get_possible_node_with_parameters(node):
            raise ParameterIsNotAllowedInOptional(
                _possible_node_with_params, self.expression
            )
        if _possible_node_with_optionals := self.get_possible_node_with_optionals(node):
            raise OptionalIsNotAllowedInOptional(
                _possible_node_with_optionals, self.expression
            )
        if self.are_nodes_empty(node):
            raise OptionalMayNotBeEmpty(node, self.expression)
        regex = "".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return rf"(?:{regex})?"

    def rewrite_alternation(self, node: Node):
        for alternative in node.nodes:
            if not len(alternative.nodes):
                raise AlternativeMayNotBeEmpty(alternative, self.expression)
            if self.are_nodes_empty(alternative):
                raise AlternativeMayNotExclusivelyContainOptionals(
                    alternative, self.expression
                )
        regex = "|".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return f"(?:{regex})"

    def rewrite_alternative(self, node: Node):
        return "".join([self.rewrite_to_regex(_node) for _node in node.nodes])

    def rewrite_parameter(self, node: Node):
        name = node.text
        parameter_type = self.parameter_type_registry.lookup_by_type_name(name)

        if not parameter_type:
            raise UndefinedParameterTypeError(node, self.expression, name)

        self.parameter_types.append(parameter_type)

        regexps = parameter_type.regexps
        if len(regexps) == 1:
            return rf"({regexps[0]})"
        return rf"((?:{')|(?:'.join(regexps)}))"

    def rewrite_expression(self, node: Node):
        regex = "".join([self.rewrite_to_regex(_node) for _node in node.nodes])
        return rf"^{regex}$"

    @staticmethod
    def are_nodes_empty(node: Node) -> bool:
        return not bool(
            [ast_node for ast_node in node.nodes if ast_node.ast_type == NodeType.TEXT]
        )

    @staticmethod
    def get_possible_node_with_parameters(node: Node) -> Optional[Node]:
        results = [
            ast_node
            for ast_node in node.nodes
            if ast_node.ast_type == NodeType.PARAMETER
        ]
        return results[0] if results else None

    @staticmethod
    def get_possible_node_with_optionals(node: Node) -> Optional[Node]:
        results = [
            ast_node
            for ast_node in node.nodes
            if ast_node.ast_type == NodeType.OPTIONAL
        ]
        return results[0] if results else None