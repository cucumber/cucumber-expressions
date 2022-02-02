from cucumber_expressions.combinatorial_generated_expression_factory import (
    CombinatorialGeneratedExpressionFactory,
)
from cucumber_expressions.parameter_type import ParameterType


class Color:
    pass


class CssColor:
    pass


class Date:
    pass


class DateTime:
    pass


class Timestamp:
    pass


class TestCombinatorialGeneratedExpressionFactory:
    def test_generates_multiple_expressions(self):
        parameter_type_combinations = [
            [
                ParameterType(
                    "color", r"red|blue|yellow", Color, lambda s: Color(), True, False
                ),
                ParameterType(
                    "csscolor",
                    r"red|blue|yellow",
                    CssColor,
                    lambda s: CssColor(),
                    True,
                    False,
                ),
            ],
            [
                ParameterType(
                    "date", r"\d{4}-\d{2}-\d{2}", Date, lambda s: Date(), True, False
                ),
                ParameterType(
                    "datetime",
                    r"\d{4}-\d{2}-\d{2}",
                    DateTime,
                    lambda s: DateTime(),
                    True,
                    False,
                ),
                ParameterType(
                    "timestamp",
                    r"\d{4}-\d{2}-\d{2}",
                    Timestamp,
                    lambda s: Timestamp(),
                    True,
                    False,
                ),
            ],
        ]

        factory = CombinatorialGeneratedExpressionFactory(
            "I bought a {%s} ball on {%s}", parameter_type_combinations
        )
        expressions = [ge.source for ge in factory.generate_expressions()]
        assert expressions == [
            "I bought a {color} ball on {date}",
            "I bought a {color} ball on {datetime}",
            "I bought a {color} ball on {timestamp}",
            "I bought a {csscolor} ball on {date}",
            "I bought a {csscolor} ball on {datetime}",
            "I bought a {csscolor} ball on {timestamp}",
        ]
