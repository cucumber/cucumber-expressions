import re

from cucumber_expressions.cucumber_expression import CucumberExpression
from cucumber_expressions.expression_factory import ExpressionFactory
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.regular_expression import RegularExpression


class TestExpressionFactory:
    def test_creates_a_regular_expression(self):
        assert isinstance(
            ExpressionFactory(ParameterTypeRegistry()).create_expression(
                re.compile("x")
            ),
            RegularExpression,
        )

    def test_creates_a_cucumber_expression(self):
        assert isinstance(
            ExpressionFactory(ParameterTypeRegistry()).create_expression("{int}"),
            CucumberExpression,
        )
