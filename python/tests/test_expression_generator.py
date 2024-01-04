import pytest

from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.expression_generator import (
    CucumberExpressionGenerator,
)
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry


class Currency:
    def __init__(self, currency: str):
        self.currency = currency


class TestCucumberExpression:
    @pytest.fixture(autouse=True)
    def defaults(self):
        self.parameter_type_registry = ParameterTypeRegistry()
        self.generator = CucumberExpressionGenerator(self.parameter_type_registry)

    def _assert_expression(self, expected_expression, expected_argument_names, text):
        generated_expression = self.generator.generate_expressions(text)[0]
        assert generated_expression.parameter_names == expected_argument_names
        assert generated_expression.source == expected_expression

        cucumber_expression = CucumberExpression(
            generated_expression.source, self.parameter_type_registry
        )
        match = cucumber_expression.match(text)
        if match is None:
            raise f"Expected text '{text}' to match generated expression '{generated_expression.source}'"
        assert len(match) == len(expected_argument_names)

    def test_documents_expression_generation(self):
        parameter_registry = ParameterTypeRegistry()
        generator = CucumberExpressionGenerator(parameter_registry)
        undefined_step_text = "I have 2 cucumbers and 1.5 tomato"
        generated_expression = generator.generate_expressions(undefined_step_text)[0]
        assert (
            generated_expression.source == "I have {int} cucumbers and {float} tomato"
        )
        assert generated_expression.parameter_names[0] == "int"
        assert generated_expression.parameter_types[1].type == float

    def test_generates_expression_for_no_args(self):
        self._assert_expression("hello", [], "hello")

    def test_generates_expression_with_escaped_left_parenthesis(self):
        self._assert_expression("\\(iii)", [], "(iii)")

    def test_generates_expression_with_escaped_left_curly_brace(self):
        self._assert_expression("\\{iii}", [], "{iii}")

    def test_generates_expression_with_escaped_slashes(self):
        self._assert_expression(
            "The {int}\\/{int}\\/{int} hey",
            ["int", "int2", "int3"],
            "The 1814/05/17 hey",
        )

    def test_generates_expression_for_int_float_arg(self):
        self._assert_expression(
            "I have {int} cukes and {float} euro",
            ["int", "float"],
            "I have 2 cukes and 1.5 euro",
        )

    def test_generates_expression_for_strings(self):
        self._assert_expression(
            "I like {string} and {string}",
            ["string", "string2"],
            "I like \"bangers\" and 'mash'",
        )

    def test_generates_expression_with_percent_sign(self):
        self._assert_expression("I am {int}% foobar", ["int"], "I am 20% foobar")

    def test_generates_expression_for_just_int(self):
        self._assert_expression("{int}", ["int"], "99999")

    def test_numbers_only_second_argument_when_builtin_type_is_not_reserved_keyword(
        self,
    ):
        self._assert_expression(
            "I have {int} cukes and {int} euro",
            ["int", "int2"],
            "I have 2 cukes and 5 euro",
        )

    def test_numbers_only_second_argument_when_type_is_not_reserved_keyword(self):
        self.parameter_type_registry.define_parameter_type(
            ParameterType(
                "currency",
                "[A-Z]{3}",
                Currency,
                lambda currency: Currency(currency),
                True,
                True,
            )
        )

        self._assert_expression(
            "I have a {currency} account and a {currency} account",
            ["currency", "currency2"],
            "I have a EUR account and a GBP account",
        )

    def test_exposes_parameters_in_generated_expression(self):
        expression = self.generator.generate_expressions("I have 2 cukes and 1.5 euro")[
            0
        ]
        types = [e.type for e in expression.parameter_types]
        assert types == [int, float]

    def test_matches_parameter_types_with_optional_capture_groups(self):
        self.parameter_type_registry.define_parameter_type(
            ParameterType(
                "optional-flight", r"(1st flight)?", str, lambda s: s, True, False
            )
        )
        self.parameter_type_registry.define_parameter_type(
            ParameterType(
                "optional-hotel", r"(1 hotel)?", str, lambda s: s, True, False
            )
        )

        expression = self.generator.generate_expressions(
            "I reach Stage 4: 1st flight -1 hotel"
        )[0]
        # While you would expect this to be `I reach Stage {int}: {optional-flight} -{optional-hotel}`
        # the `-1` causes {int} to match just before {optional-hotel}.
        assert expression.source == "I reach Stage {int}: {optional-flight} {int} hotel"

    def test_generates_at_most_256_expressions(self):
        for i in range(3):
            self.parameter_type_registry.define_parameter_type(
                ParameterType(
                    f"my-type-{i}", r"([a-z] )*?[a-z]", str, lambda s: s, True, False
                )
            )

        # This would otherwise generate 4^11=4194300 expressions and consume just shy of 1.5GB.
        expressions = self.generator.generate_expressions("a s i m p l e s t e p")
        assert len(expressions) == 256

    def test_prefers_expression_with_longest_non_empty_match(self):
        self.parameter_type_registry.define_parameter_type(
            ParameterType("zero-or-more", r"[a-z]*", str, lambda s: s, True, False)
        )
        self.parameter_type_registry.define_parameter_type(
            ParameterType("exactly-one", r"[a-z]", str, lambda s: s, True, False)
        )

        expressions = self.generator.generate_expressions("a simple step")
        assert len(expressions) == 2
        assert expressions[0].source == "{exactly-one} {zero-or-more} {zero-or-more}"
        assert expressions[1].source == "{zero-or-more} {zero-or-more} {zero-or-more}"

    @pytest.fixture(autouse=True)
    def direction_parameter_type_registry_generator(self):
        direction_parameter_type_registry = self.parameter_type_registry
        direction_parameter_type_registry.define_parameter_type(
            ParameterType("direction", r"(up|down)", str, lambda s: s, True, False)
        )
        self.direction_generator = CucumberExpressionGenerator(
            direction_parameter_type_registry
        )

    def test_does_not_suggest_parameter_when_match_is_at_the_beginning_of_a_word(self):
        assert (
            self.direction_generator.generate_expressions("When I download a picture")[
                0
            ].source
            != "When I {direction}load a picture"
        )
        assert (
            self.direction_generator.generate_expressions("When I download a picture")[
                0
            ].source
            == "When I download a picture"
        )

    def test_does_not_suggest_parameter_when_match_is_inside_a_word(self):
        assert (
            self.direction_generator.generate_expressions(
                "When I watch the muppet show"
            )[0].source
            != "When I watch the m{direction}pet show"
        )
        assert (
            self.direction_generator.generate_expressions(
                "When I watch the muppet show"
            )[0].source
            == "When I watch the muppet show"
        )

    def test_does_not_suggest_parameter_when_match_at_the_end_of_a_word(self):
        assert (
            self.direction_generator.generate_expressions("When I create a group")[
                0
            ].source
            != "When I create a gro{direction}"
        )
        assert (
            self.direction_generator.generate_expressions("When I create a group")[
                0
            ].source
            == "When I create a group"
        )

    def test_does_suggest_parameter_when_match_is_a_full_word(self):
        assert (
            self.direction_generator.generate_expressions("When I go down the road")[
                0
            ].source
            == "When I go {direction} the road"
        )
        assert (
            self.direction_generator.generate_expressions("When I walk up the hill")[
                0
            ].source
            == "When I walk {direction} the hill"
        )
        assert (
            self.direction_generator.generate_expressions(
                "up the hill, the road goes down"
            )[0].source
            == "{direction} the hill, the road goes {direction}"
        )

    def test_does_suggest_parameter_when_match_wrapped_around_punctuation_characters(
        self,
    ):
        assert (
            self.direction_generator.generate_expressions("When direction is:down")[
                0
            ].source
            == "When direction is:{direction}"
        )
        assert (
            self.direction_generator.generate_expressions("Then direction is down.")[
                0
            ].source
            == "Then direction is {direction}."
        )
