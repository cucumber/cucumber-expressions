defmodule Cucumber.CucumberExpressions.BangFunctionsTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions

  alias Cucumber.CucumberExpressions.{
    CucumberExpression,
    Error,
    ParameterType,
    ParameterTypeRegistry,
    CucumberExpressionParser,
    CucumberExpressionTokenizer,
    UndefinedParameterTypeError
  }

  defp registry, do: ParameterTypeRegistry.new()

  test "CucumberExpression.compile!/2 raises what compile/2 returns" do
    assert {:error, %UndefinedParameterTypeError{}} =
             CucumberExpression.compile("{unknown}", registry())

    assert_raise UndefinedParameterTypeError, fn ->
      CucumberExpression.compile!("{unknown}", registry())
    end
  end

  test "CucumberExpressions.compile!/2 raises what compile/2 returns" do
    assert {:error, %UndefinedParameterTypeError{}} =
             CucumberExpressions.compile("{unknown}", registry())

    assert_raise UndefinedParameterTypeError, fn ->
      CucumberExpressions.compile!("{unknown}", registry())
    end
  end

  test "CucumberExpressionTokenizer.tokenize!/1 raises what tokenize/1 returns" do
    assert {:error, %Error{}} = CucumberExpressionTokenizer.tokenize("\\")
    assert_raise Error, fn -> CucumberExpressionTokenizer.tokenize!("\\") end
  end

  test "CucumberExpressionTokenizer.tokenize!/1 returns tokens when there is no error" do
    assert [_ | _] = CucumberExpressionTokenizer.tokenize!("three blind mice")
  end

  test "CucumberExpressionParser.parse!/1 raises what parse/1 returns" do
    assert {:error, %Error{}} = CucumberExpressionParser.parse("(unclosed")
    assert_raise Error, fn -> CucumberExpressionParser.parse!("(unclosed") end
  end

  test "CucumberExpressionParser.parse!/1 returns the AST when there is no error" do
    assert %{type: :expression_node} = CucumberExpressionParser.parse!("three blind mice")
  end

  test "ParameterType.new!/1 raises what new/1 returns" do
    assert {:error, %Error{}} = ParameterType.new(name: "[string]", regexps: ".*")

    assert_raise Error, fn ->
      ParameterType.new!(name: "[string]", regexps: ".*")
    end
  end

  test "ParameterTypeRegistry.add!/2 raises what add/2 returns" do
    duplicate = ParameterType.new!(name: "int", regexps: "\\d+")

    assert {:error, %Error{}} = ParameterTypeRegistry.define_parameter_type(registry(), duplicate)

    assert_raise Error, fn ->
      ParameterTypeRegistry.define_parameter_type!(registry(), duplicate)
    end
  end
end
