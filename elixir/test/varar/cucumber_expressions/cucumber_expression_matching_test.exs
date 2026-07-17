defmodule Varar.CucumberExpressions.CucumberExpressionMatchingTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{
    Argument,
    CucumberExpression,
    ParameterTypeRegistry,
    Testdata
  }

  for {name, fixture} <- Testdata.load("cucumber-expression/matching") do
    @fixture fixture
    if Map.has_key?(fixture, "exception") do
      test "rejects #{name}" do
        %{"expression" => expression, "exception" => expected} = @fixture
        registry = ParameterTypeRegistry.new()

        assert {:error, error} = CucumberExpression.compile(expression, registry)
        assert Exception.message(error) == expected
      end
    else
      test "matches #{name}" do
        fixture = @fixture
        registry = ParameterTypeRegistry.new()
        compiled = CucumberExpression.compile!(fixture["expression"], registry)

        values =
          case CucumberExpression.match(compiled, fixture["text"]) do
            nil -> nil
            args -> Enum.map(args, &Testdata.format_value(Argument.value(&1)))
          end

        assert values == Map.get(fixture, "expected_args")
      end
    end
  end
end
