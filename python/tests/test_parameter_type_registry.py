import pytest

from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.errors import (
    CucumberExpressionError,
    AmbiguousParameterTypeError,
)

CAPITALISED_WORD = r"[A-Z]+\w+"


class Name:
    pass


class Person:
    pass


class Place:
    pass


class TestParameterTypeRegistration:
    def test_does_not_allow_more_than_one_prefer_for_regexp_match_parameter_type_for_each_regexp(
        self,
    ):
        registry = ParameterTypeRegistry()
        registry.define_parameter_type(
            ParameterType("name", CAPITALISED_WORD, Name, lambda s: Name(), True, True)
        )
        registry.define_parameter_type(
            ParameterType(
                "person", CAPITALISED_WORD, Person, lambda s: Person(), True, False
            )
        )
        with pytest.raises(CucumberExpressionError):
            registry.define_parameter_type(
                ParameterType(
                    "place", CAPITALISED_WORD, Place, lambda s: Place(), True, True
                )
            )

    def test_looks_up_prefer_for_regexp_match_parameter_type_by_regexp(self):
        registry = ParameterTypeRegistry()

        name = ParameterType(
            "name", CAPITALISED_WORD, Name, lambda s: Name(), True, False
        )
        person = ParameterType(
            "person", CAPITALISED_WORD, Person, lambda s: Person(), True, True
        )
        place = ParameterType(
            "place", CAPITALISED_WORD, Place, lambda s: Place(), True, False
        )

        registry.define_parameter_type(name)
        registry.define_parameter_type(person)
        registry.define_parameter_type(place)

        assert (
            registry.lookup_by_regexp(
                str(CAPITALISED_WORD), r"([A-Z]+\w+) and ([A-Z]+\w+)", "Lisa and Bob"
            )
            == person
        )

    def test_throws_ambiguous_exception_when_no_parameter_types_are_prefer_for_regexp_match(
        self,
    ):
        registry = ParameterTypeRegistry()

        name = ParameterType(
            "name", CAPITALISED_WORD, Name, lambda s: Name(), True, False
        )
        person = ParameterType(
            "person", CAPITALISED_WORD, Person, lambda s: Person(), True, False
        )
        place = ParameterType(
            "place", CAPITALISED_WORD, Place, lambda s: Place(), True, False
        )

        registry.define_parameter_type(name)
        registry.define_parameter_type(person)
        registry.define_parameter_type(place)

        with pytest.raises(AmbiguousParameterTypeError):
            assert (
                registry.lookup_by_regexp(
                    CAPITALISED_WORD, r"([A-Z]+\w+) and ([A-Z]+\w+)", "Lisa and Bob"
                )
                == person
            )
