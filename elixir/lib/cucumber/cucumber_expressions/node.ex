defmodule Cucumber.CucumberExpressions.Node do
  @moduledoc """
  A node in the AST produced by `Cucumber.CucumberExpressions.Parser`.

  Leaf (text) nodes carry a `token` and have `nodes: nil`; container nodes
  carry a (possibly empty) list of child `nodes` and an empty `token`.
  `start` and `end` are codepoint offsets into the expression source.
  """

  @enforce_keys [:type, :start, :end]
  defstruct [:type, :start, :end, token: "", nodes: nil]

  @type type ::
          :text_node
          | :optional_node
          | :alternation_node
          | :alternative_node
          | :parameter_node
          | :expression_node

  @type t :: %__MODULE__{
          type: type(),
          start: non_neg_integer(),
          end: non_neg_integer(),
          token: String.t(),
          nodes: [t()] | nil
        }

  @type_strings %{
    text_node: "TEXT_NODE",
    optional_node: "OPTIONAL_NODE",
    alternation_node: "ALTERNATION_NODE",
    alternative_node: "ALTERNATIVE_NODE",
    parameter_node: "PARAMETER_NODE",
    expression_node: "EXPRESSION_NODE"
  }

  @doc "The upstream string name of a node type, e.g. `\"TEXT_NODE\"`."
  def type_string(type), do: Map.fetch!(@type_strings, type)

  @doc "The atom node type for an upstream string name."
  def type_from_string(string) do
    {type, _} = Enum.find(@type_strings, fn {_, s} -> s == string end)
    type
  end

  @doc "The source text covered by this node."
  def text(%__MODULE__{token: token, nodes: nil}), do: token

  def text(%__MODULE__{token: token, nodes: nodes}) do
    Enum.reduce(nodes, token, fn node, acc -> acc <> text(node) end)
  end
end
