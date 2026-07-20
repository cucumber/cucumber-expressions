defmodule Cucumber.CucumberExpressions.CucumberExpressionTransformationTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{CucumberExpression, ParameterTypeRegistry, Testdata}

  for {name, fixture} <- Testdata.load("cucumber-expression/transformation") do
    @fixture fixture
    test "transforms #{name}" do
      %{"expression" => expression, "expected_regex" => expected} = @fixture
      registry = ParameterTypeRegistry.new()

      assert {:ok, compiled} = CucumberExpression.compile(expression, registry)
      assert Regex.source(CucumberExpression.regexp(compiled)) == expected
    end
  end
end
