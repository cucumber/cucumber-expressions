from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.expression_factory import ExpressionFactory
from cucumber_expressions.regular_expression import RegularExpression


def test_expression_factory_regex():
    input_str = r"I have (?P<cuke_count>\d+) cukes? in my (?P<word>\w+) now"
    expression = ExpressionFactory().create_expression(input_str)
    assert isinstance(expression, RegularExpression)
    matches = expression.match('I have 4 cukes in my belly now')
    assert matches[0].value == 4
    assert matches[0].name == "cuke_count"
    assert matches[1].value == "belly"
    assert matches[1].name == "word"


def test_expression_factory_cucumber_expression():
    input_str = "I have {name:int} cukes in my {string} now"
    expression = ExpressionFactory().create_expression(input_str)
    assert isinstance(expression, CucumberExpression)
    matches = expression.match("I have 4 cukes in my \"belly\" now")
    assert matches[0].value == 4
    assert matches[0].name == "name"
    assert matches[1].value == "belly"
    assert matches[1].name is None


def test_expression_factory_invalid():
    input_str = "^(?:(\d{2,4})-)?(\d{1,3})\s*([A-Za-z]{3})\s*(?:\{(\d+,\d+|\d+)\})?(\d{1,2})(?:\{[A-Za-z0-9]+\})?$"
    expression = ExpressionFactory().create_expression(input_str)
    assert isinstance(expression, RegularExpression)
