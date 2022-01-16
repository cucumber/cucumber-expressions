from cucumber_expressions.argument import Argument
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry
from cucumber_expressions.tree_regexp import TreeRegexp


class TestArgument:
    def test_exposes_parameter_type(self):
        tree_regexp = TreeRegexp(r"three (.*) mice")
        parameter_type_registry = ParameterTypeRegistry()
        arguments = Argument.build(
            tree_regexp,
            "three blind mice",
            [parameter_type_registry.lookup_by_type_name("string")],
        )
        assert arguments[0].parameter_type.name == "string"
