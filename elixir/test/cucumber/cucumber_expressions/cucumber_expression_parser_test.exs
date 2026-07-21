defmodule Cucumber.CucumberExpressions.CucumberExpressionParserTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.CucumberExpressionParser
  alias Cucumber.CucumberExpressions.Node
  alias Cucumber.CucumberExpressions.Testdata

  for {name, fixture} <- Testdata.load("cucumber-expression/parser") do
    @fixture fixture
    if Map.has_key?(fixture, "exception") do
      test "rejects #{name}" do
        %{"expression" => expression, "exception" => expected} = @fixture
        assert {:error, error} = CucumberExpressionParser.parse(expression)
        assert Exception.message(error) == expected
      end
    else
      test "parses #{name}" do
        %{"expression" => expression, "expected_ast" => expected} = @fixture
        assert {:ok, ast} = CucumberExpressionParser.parse(expression)
        assert ast == node_from_map(expected)
      end
    end
  end

  defp node_from_map(map) do
    %Node{
      type: Node.type_from_string(map["type"]),
      start: map["start"],
      end: map["end"],
      token: Map.get(map, "token", ""),
      nodes:
        case Map.get(map, "nodes") do
          nil -> nil
          nodes -> Enum.map(nodes, &node_from_map/1)
        end
    }
  end
end
