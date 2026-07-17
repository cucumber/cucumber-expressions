defmodule Varar.CucumberExpressions.RegularExpressionMatchingTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{
    Argument,
    ParameterTypeRegistry,
    RegularExpression,
    Testdata
  }

  for {name, fixture} <- Testdata.load("regular-expression/matching") do
    @fixture fixture
    test "matches #{name}" do
      fixture = @fixture
      registry = ParameterTypeRegistry.new()
      expression = RegularExpression.compile!(fixture["expression"], registry)

      values =
        case RegularExpression.match(expression, fixture["text"]) do
          nil -> nil
          args -> Enum.map(args, &Testdata.format_value(Argument.value(&1)))
        end

      assert values == fixture["expected_args"]
    end
  end
end
