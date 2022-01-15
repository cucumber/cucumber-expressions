import re

from Cucumber.CucumberExpressions.cucumber_expression import CucumberExpression
from Cucumber.CucumberExpressions.expression_factory import ExpressionFactory
from Cucumber.CucumberExpressions.parameter_type_registry import ParameterTypeRegistry
from Cucumber.CucumberExpressions.regular_expression import RegularExpression


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
