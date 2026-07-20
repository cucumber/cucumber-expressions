defmodule Varar.CucumberExpressions.RegularExpressionTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{Error, ParameterTypeRegistry, RegularExpression}

  defp registry, do: ParameterTypeRegistry.new()

  test "compile/2 returns an error for named capture groups" do
    assert {:error, %Error{} = error} =
             RegularExpression.compile(~r/I have (?<count>\d+) cukes/, registry())

    assert Exception.message(error) =~ "Named capture groups are not supported"
  end

  test "compile!/2 raises for named capture groups" do
    assert_raise Error, fn ->
      RegularExpression.compile!(~r/I have (?<count>\d+) cukes/, registry())
    end
  end

  test "compile/2 returns an ok tuple for a supported regexp" do
    assert {:ok, %RegularExpression{}} =
             RegularExpression.compile(~r/I have (\d+) cukes/, registry())
  end

  test "compile/2 accepts a regexp source string" do
    assert {:ok, expression} = RegularExpression.compile("I have (\\d+) cukes", registry())
    assert RegularExpression.source(expression) == "I have (\\d+) cukes"
  end
end
