defmodule Cucumber.CucumberExpressions.ArgumentTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{Argument, Error, ParameterTypeRegistry, TreeRegexp}

  defp string_type do
    ParameterTypeRegistry.new()
    |> ParameterTypeRegistry.lookup_by_type_name("string")
  end

  test "exposes parameter_type" do
    tree_regexp = TreeRegexp.new!(~r/three (.*) mice/)

    [argument] = Argument.build(tree_regexp, "three blind mice", [string_type()])
    assert argument.parameter_type.name == "string"
  end

  test "returns nil when the text does not match" do
    tree_regexp = TreeRegexp.new!(~r/three (.*) mice/)

    assert Argument.build(tree_regexp, "four blind mice", [string_type()]) == nil
  end

  test "raises when there are more capture groups than parameter types" do
    tree_regexp = TreeRegexp.new!(~r/three (.*) (.*) mice/)

    assert_raise Error, fn ->
      Argument.build(tree_regexp, "three blind happy mice", [string_type()])
    end
  end

  test "raises when there are more parameter types than capture groups" do
    tree_regexp = TreeRegexp.new!(~r/three (.*) mice/)

    error =
      assert_raise Error, fn ->
        Argument.build(tree_regexp, "three blind mice", [string_type(), string_type()])
      end

    assert error.message =~ "has 1 capture groups"
    assert error.message =~ "but there were 2 parameter types"
  end
end
