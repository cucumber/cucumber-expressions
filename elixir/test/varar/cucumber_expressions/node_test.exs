defmodule Varar.CucumberExpressions.NodeTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.Node

  test "type_string/1 returns the upstream name" do
    assert Node.type_string(:text_node) == "TEXT_NODE"
    assert Node.type_string(:optional_node) == "OPTIONAL_NODE"
    assert Node.type_string(:alternation_node) == "ALTERNATION_NODE"
    assert Node.type_string(:alternative_node) == "ALTERNATIVE_NODE"
    assert Node.type_string(:parameter_node) == "PARAMETER_NODE"
    assert Node.type_string(:expression_node) == "EXPRESSION_NODE"
  end

  test "type_string/1 and type_from_string/1 round-trip" do
    for type <- [
          :text_node,
          :optional_node,
          :alternation_node,
          :alternative_node,
          :parameter_node,
          :expression_node
        ] do
      assert type |> Node.type_string() |> Node.type_from_string() == type
    end
  end
end
