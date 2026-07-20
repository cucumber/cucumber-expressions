defmodule Cucumber.CucumberExpressions.CucumberExpression do
  @moduledoc """
  A compiled Cucumber Expression.

  Created with `compile/2` (or `compile!/2`) against a
  `Cucumber.CucumberExpressions.ParameterTypeRegistry`; match text with `match/2`.
  """

  alias Cucumber.CucumberExpressions.{
    Argument,
    CucumberExpressionParser,
    Error,
    Node,
    ParameterTypeRegistry,
    TreeRegexp,
    UndefinedParameterTypeError
  }

  @enforce_keys [:source, :tree_regexp, :parameter_types]
  defstruct [:source, :tree_regexp, :parameter_types]

  @type t :: %__MODULE__{
          source: String.t(),
          tree_regexp: TreeRegexp.t(),
          parameter_types: [Cucumber.CucumberExpressions.ParameterType.t()]
        }

  @escape_pattern ~r/([\\^\[({$.|?*+})\]])/

  @spec compile(String.t(), ParameterTypeRegistry.t()) ::
          {:ok, t()} | {:error, Error.t() | UndefinedParameterTypeError.t()}
  def compile(expression, %ParameterTypeRegistry{} = registry) do
    with {:ok, ast} <- CucumberExpressionParser.parse(expression),
         {:ok, pattern, parameter_types} <- rewrite_to_regex(ast, expression, registry) do
      {:ok,
       %__MODULE__{
         source: expression,
         tree_regexp: TreeRegexp.new!(pattern),
         parameter_types: parameter_types
       }}
    end
  end

  @spec compile!(String.t(), ParameterTypeRegistry.t()) :: t()
  def compile!(expression, %ParameterTypeRegistry{} = registry) do
    case compile(expression, registry) do
      {:ok, compiled} -> compiled
      {:error, error} -> raise error
    end
  end

  @doc """
  Matches `text` against the expression. Returns a list of
  `Cucumber.CucumberExpressions.Argument`s (get each value with
  `Argument.value/1`), or `nil` if the text does not match.
  """
  @spec match(t(), String.t()) :: [Argument.t()] | nil
  def match(%__MODULE__{tree_regexp: tree_regexp, parameter_types: parameter_types}, text) do
    Argument.build(tree_regexp, text, parameter_types)
  end

  @doc "The compiled `Regex` for this expression."
  @spec regexp(t()) :: Regex.t()
  def regexp(%__MODULE__{tree_regexp: tree_regexp}), do: tree_regexp.regexp

  # Rewrites an AST node to a regex source string, accumulating the parameter
  # types referenced by the expression in match order.
  defp rewrite_to_regex(ast, expression, registry) do
    with {:ok, pattern, reversed_parameter_types} <- rewrite(ast, expression, registry, []) do
      {:ok, pattern, Enum.reverse(reversed_parameter_types)}
    end
  end

  defp rewrite(%Node{type: :text_node, token: token}, _expression, _registry, acc) do
    {:ok, process_escapes(token), acc}
  end

  defp rewrite(%Node{type: :optional_node} = node, expression, registry, acc) do
    with :ok <- assert_no_parameters(node, expression),
         :ok <- assert_no_optionals(node, expression),
         :ok <- assert_not_empty(node, expression, &Error.optional_may_not_be_empty/2) do
      rewrite_nodes(node.nodes, "", "(?:", ")?", expression, registry, acc)
    end
  end

  defp rewrite(%Node{type: :alternation_node} = node, expression, registry, acc) do
    with :ok <- assert_alternatives_valid(node, expression) do
      rewrite_nodes(node.nodes, "|", "(?:", ")", expression, registry, acc)
    end
  end

  defp rewrite(%Node{type: :alternative_node} = node, expression, registry, acc) do
    rewrite_nodes(node.nodes, "", "", "", expression, registry, acc)
  end

  defp rewrite(%Node{type: :parameter_node} = node, expression, registry, acc) do
    type_name = Node.text(node)

    case ParameterTypeRegistry.lookup_by_type_name(registry, type_name) do
      nil ->
        {:error, UndefinedParameterTypeError.new(expression, node, type_name)}

      parameter_type ->
        {:ok, build_capture_regexp(parameter_type.regexps), [parameter_type | acc]}
    end
  end

  defp rewrite(%Node{type: :expression_node} = node, expression, registry, acc) do
    rewrite_nodes(node.nodes, "", "^", "$", expression, registry, acc)
  end

  defp rewrite_nodes(nodes, delimiter, prefix, suffix, expression, registry, acc) do
    result =
      Enum.reduce_while(nodes, {:ok, [], acc}, fn node, {:ok, patterns, acc} ->
        case rewrite(node, expression, registry, acc) do
          {:ok, pattern, acc} -> {:cont, {:ok, [pattern | patterns], acc}}
          {:error, _} = error -> {:halt, error}
        end
      end)

    with {:ok, patterns, acc} <- result do
      {:ok, prefix <> Enum.join(Enum.reverse(patterns), delimiter) <> suffix, acc}
    end
  end

  defp build_capture_regexp([regexp]), do: "(" <> regexp <> ")"

  defp build_capture_regexp(regexps) do
    "(" <> Enum.map_join(regexps, "|", &"(?:#{&1})") <> ")"
  end

  defp process_escapes(text), do: Regex.replace(@escape_pattern, text, "\\\\\\1")

  defp assert_alternatives_valid(%Node{nodes: alternatives}, expression) do
    Enum.reduce_while(alternatives, :ok, fn alternative, :ok ->
      cond do
        alternative.nodes == [] ->
          {:halt, {:error, Error.alternative_may_not_be_empty(expression, alternative)}}

        not Enum.any?(alternative.nodes, &(&1.type == :text_node)) ->
          {:halt,
           {:error,
            Error.alternative_may_not_exclusively_contain_optionals(expression, alternative)}}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp assert_not_empty(%Node{nodes: nodes} = node, expression, build_error) do
    if Enum.any?(nodes, &(&1.type == :text_node)) do
      :ok
    else
      {:error, build_error.(expression, node)}
    end
  end

  defp assert_no_parameters(%Node{nodes: nodes}, expression) do
    case Enum.find(nodes, &(&1.type == :parameter_node)) do
      nil -> :ok
      child -> {:error, Error.parameter_is_not_allowed_in_optional(expression, child)}
    end
  end

  defp assert_no_optionals(%Node{nodes: nodes}, expression) do
    case Enum.find(nodes, &(&1.type == :optional_node)) do
      nil -> :ok
      child -> {:error, Error.optional_is_not_allowed_in_optional(expression, child)}
    end
  end
end
