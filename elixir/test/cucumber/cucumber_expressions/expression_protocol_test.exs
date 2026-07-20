defmodule Cucumber.CucumberExpressions.ExpressionProtocolTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.Argument
  alias Cucumber.CucumberExpressions.CucumberExpression
  alias Cucumber.CucumberExpressions.Expression
  alias Cucumber.CucumberExpressions.ParameterTypeRegistry
  alias Cucumber.CucumberExpressions.RegularExpression

  defp registry, do: ParameterTypeRegistry.new()

  describe "CucumberExpression" do
    setup do
      {:ok, expression: CucumberExpression.compile!("I have {int} cukes", registry())}
    end

    test "match/2 delegates to the underlying expression", %{expression: expression} do
      assert [argument] = Expression.match(expression, "I have 42 cukes")
      assert Argument.value(argument) == 42
      assert Expression.match(expression, "no match") == nil
    end

    test "source/1 returns the Cucumber Expression source", %{expression: expression} do
      assert Expression.source(expression) == "I have {int} cukes"
    end

    test "regex/1 returns the compiled Regex", %{expression: expression} do
      assert %Regex{} = regex = Expression.regexp(expression)
      assert Regex.source(regex) == Regex.source(CucumberExpression.regexp(expression))
      assert Regex.match?(regex, "I have 42 cukes")
    end
  end

  describe "RegularExpression" do
    setup do
      {:ok, expression: RegularExpression.compile!(~r/I have (\d+) cukes/, registry())}
    end

    test "match/2 delegates to the underlying expression", %{expression: expression} do
      assert [argument] = Expression.match(expression, "I have 42 cukes")
      assert Argument.value(argument) == 42
      assert Expression.match(expression, "no match") == nil
    end

    test "source/1 returns the regexp source", %{expression: expression} do
      assert Expression.source(expression) == "I have (\\d+) cukes"
      assert RegularExpression.source(expression) == "I have (\\d+) cukes"
    end

    test "regex/1 returns the compiled Regex", %{expression: expression} do
      assert %Regex{} = regex = Expression.regexp(expression)
      assert regex == RegularExpression.regexp(expression)
      assert Regex.match?(regex, "I have 42 cukes")
    end
  end
end
