defmodule Cucumber.CucumberExpressions.ExpressionFactoryTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions, as: CE

  alias Cucumber.CucumberExpressions.{
    CucumberExpression,
    ParameterTypeRegistry,
    RegularExpression
  }

  setup do
    {:ok, registry: ParameterTypeRegistry.new()}
  end

  test "creates a RegularExpression from a Regex", %{registry: registry} do
    assert %RegularExpression{} = CE.compile!(~r/x/, registry)
  end

  test "creates a CucumberExpression from a string", %{registry: registry} do
    assert %CucumberExpression{} = CE.compile!("{int}", registry)
  end

  test "matches through the Expression protocol", %{registry: registry} do
    cucumber_expression = CE.compile!("I have {int} cuke(s)", registry)
    regular_expression = CE.compile!(~r/I have (\d+) cukes?/, registry)

    for expression <- [cucumber_expression, regular_expression] do
      args = CE.Expression.match(expression, "I have 7 cukes")
      assert Enum.map(args, &CE.Argument.value/1) == [7]
      assert CE.Expression.match(expression, "I have no cukes") == nil
    end
  end
end
