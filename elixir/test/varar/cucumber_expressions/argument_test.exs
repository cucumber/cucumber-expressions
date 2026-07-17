defmodule Varar.CucumberExpressions.ArgumentTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{Argument, ParameterTypeRegistry, TreeRegexp}

  test "exposes parameter_type" do
    tree_regexp = TreeRegexp.new!(~r/three (.*) mice/)
    registry = ParameterTypeRegistry.new()
    string_type = ParameterTypeRegistry.lookup_by_type_name(registry, "string")

    [argument] = Argument.build(tree_regexp, "three blind mice", [string_type])
    assert argument.parameter_type.name == "string"
  end
end
