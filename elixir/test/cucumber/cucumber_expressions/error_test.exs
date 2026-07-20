defmodule Cucumber.CucumberExpressions.ErrorTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{Error, ParameterType, ParameterTypeRegistry}
  alias Cucumber.CucumberExpressions.CucumberExpression, as: CE

  # These assert on the structured `type` atom, which lets Elixir callers
  # pattern-match on the kind of problem without depending on the (conformance
  # fixed) message string. The exact messages are covered by the shared
  # testdata suites.

  defp compile_error(source) do
    registry = ParameterTypeRegistry.new()
    assert {:error, %Error{} = error} = CE.compile(source, registry)
    error
  end

  test "empty optional carries type :optional_may_not_be_empty" do
    assert %Error{type: :optional_may_not_be_empty} = compile_error("three ()")
  end

  test "parameter inside optional carries type :parameter_is_not_allowed_in_optional" do
    assert %Error{type: :parameter_is_not_allowed_in_optional} = compile_error("({int})")
  end

  test "nested optional carries type :optional_is_not_allowed_in_optional" do
    assert %Error{type: :optional_is_not_allowed_in_optional} = compile_error("a ((b))")
  end

  test "empty alternative carries type :alternative_may_not_be_empty" do
    assert %Error{type: :alternative_may_not_be_empty} = compile_error("a/ b")
  end

  test "unclosed parameter carries type :missing_end_token" do
    assert %Error{type: :missing_end_token} = compile_error("a {int")
  end

  test "escaping the end of line carries type :end_of_line_cannot_be_escaped" do
    assert %Error{type: :end_of_line_cannot_be_escaped} = compile_error("a\\")
  end

  test "the type travels through the {:error, _} tuple and Exception.message/1 still works" do
    error = compile_error("three ()")
    assert error.type == :optional_may_not_be_empty
    assert Exception.message(error) =~ "An optional must contain some text"
  end

  test "an invalid parameter type name carries type :invalid_parameter_type_name" do
    assert {:error, %Error{type: :invalid_parameter_type_name}} =
             ParameterType.new(name: "[string]", regexps: ".*")
  end

  test "a duplicate parameter type name carries type :duplicate_parameter_type_name" do
    registry = ParameterTypeRegistry.new()
    duplicate = ParameterType.new!(name: "int", regexps: "\\d+")

    assert {:error, %Error{type: :duplicate_parameter_type_name}} =
             ParameterTypeRegistry.define_parameter_type(registry, duplicate)
  end
end
