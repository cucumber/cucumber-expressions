defmodule Varar.CucumberExpressions.Parser do
  @moduledoc """
  Parses a Cucumber Expression source string into an AST of
  `Varar.CucumberExpressions.Node`s.

  A recursive-descent port of the upstream parser. Each sub-parser returns
  `{:ok, consumed, node}` — `consumed == 0` signals "no match, try the next
  parser" — or `{:error, error}`.
  """

  alias Varar.CucumberExpressions.{Error, Node, Tokenizer}

  @spec parse(String.t()) :: {:ok, Node.t()} | {:error, Error.t()}
  def parse(expression) do
    with {:ok, token_list} <- Tokenizer.tokenize(expression) do
      tokens = List.to_tuple(token_list)

      case parse_expression(expression, tokens, 0) do
        {:error, _} = error ->
          error

        {:ok, consumed, ast} when consumed == tuple_size(tokens) ->
          {:ok, ast}

        {:ok, _, _} ->
          # Can't happen if configured properly
          {:error, %Error{type: :could_not_parse, message: "Could not parse" <> expression}}
      end
    end
  end

  @spec parse!(String.t()) :: Node.t()
  def parse!(expression) do
    case parse(expression) do
      {:ok, ast} -> ast
      {:error, error} -> raise error
    end
  end

  # cucumber-expression := ( alternation | optional | parameter | text )*
  defp parse_expression(expression, tokens, current) do
    parse_between(
      :expression_node,
      :start_of_line,
      :end_of_line,
      [&parse_alternation/3, &parse_optional/3, &parse_parameter/3, &parse_text/3],
      expression,
      tokens,
      current
    )
  end

  # optional := '(' + option* + ')'
  # option := optional | parameter | text
  defp parse_optional(expression, tokens, current) do
    parse_between(
      :optional_node,
      :begin_optional,
      :end_optional,
      [&parse_optional/3, &parse_parameter/3, &parse_text/3],
      expression,
      tokens,
      current
    )
  end

  # parameter := '{' + name* + '}'
  defp parse_parameter(expression, tokens, current) do
    parse_between(
      :parameter_node,
      :begin_parameter,
      :end_parameter,
      [&parse_name/3],
      expression,
      tokens,
      current
    )
  end

  # text := whitespace | ')' | '}' | .
  defp parse_text(expression, tokens, current) do
    token = elem(tokens, current)

    case token.type do
      type when type in [:white_space, :text, :end_parameter, :end_optional] ->
        {:ok, 1, %Node{type: :text_node, start: token.start, end: token.end, token: token.text}}

      :alternation ->
        {:error, Error.alternation_not_allowed_in_optional(expression, token)}

      _ ->
        # If configured correctly this will never happen
        {:ok, 0, nil}
    end
  end

  # name := whitespace | .
  defp parse_name(expression, tokens, current) do
    token = elem(tokens, current)

    case token.type do
      type when type in [:white_space, :text] ->
        {:ok, 1, %Node{type: :text_node, start: token.start, end: token.end, token: token.text}}

      type
      when type in [
             :begin_parameter,
             :end_parameter,
             :begin_optional,
             :end_optional,
             :alternation
           ] ->
        {:error, Error.invalid_parameter_type_name_in_node(expression, token)}

      _ ->
        # If configured correctly this will never happen
        {:ok, 0, nil}
    end
  end

  # alternation := (?<=left-boundary) + alternative* + ( '/' + alternative* )+ + (?=right-boundary)
  # left-boundary := whitespace | } | ^
  # right-boundary := whitespace | { | $
  # alternative := optional | parameter | text
  defp parse_alternation(expression, tokens, current) do
    if looking_at_any(tokens, current - 1, [:start_of_line, :white_space, :end_parameter]) do
      parsers = [
        &parse_alternative_separator/3,
        &parse_optional/3,
        &parse_parameter/3,
        &parse_text/3
      ]

      with {:ok, consumed, sub_ast} <-
             parse_tokens_until(
               expression,
               parsers,
               tokens,
               current,
               [:white_space, :end_of_line, :begin_parameter]
             ) do
        build_alternation(tokens, current, consumed, sub_ast)
      end
    else
      {:ok, 0, nil}
    end
  end

  defp build_alternation(tokens, current, consumed, sub_ast) do
    if Enum.any?(sub_ast, &(&1.type == :alternative_node)) do
      # Does not consume the right hand boundary token
      start = elem(tokens, current).start
      end_ = elem(tokens, current + consumed).start

      node = %Node{
        type: :alternation_node,
        start: start,
        end: end_,
        nodes: split_alternatives(start, end_, sub_ast)
      }

      {:ok, consumed, node}
    else
      {:ok, 0, nil}
    end
  end

  defp parse_alternative_separator(_expression, tokens, current) do
    if looking_at(tokens, current, :alternation) do
      token = elem(tokens, current)

      {:ok, 1,
       %Node{type: :alternative_node, start: token.start, end: token.end, token: token.text}}
    else
      {:ok, 0, nil}
    end
  end

  defp parse_between(node_type, begin_type, end_type, parsers, expression, tokens, current) do
    if looking_at(tokens, current, begin_type) do
      with {:ok, consumed, sub_ast} <-
             parse_tokens_until(expression, parsers, tokens, current + 1, [end_type, :end_of_line]) do
        sub_current = current + 1 + consumed

        close_between(
          node_type,
          begin_type,
          end_type,
          expression,
          tokens,
          current,
          sub_current,
          sub_ast
        )
      end
    else
      {:ok, 0, nil}
    end
  end

  defp close_between(
         node_type,
         begin_type,
         end_type,
         expression,
         tokens,
         current,
         sub_current,
         sub_ast
       ) do
    if looking_at(tokens, sub_current, end_type) do
      # Consumes the end token
      start = elem(tokens, current).start
      end_ = elem(tokens, sub_current).end

      {:ok, sub_current + 1 - current,
       %Node{type: node_type, start: start, end: end_, nodes: sub_ast}}
    else
      {:error, Error.missing_end_token(expression, begin_type, end_type, elem(tokens, current))}
    end
  end

  defp parse_tokens_until(expression, parsers, tokens, start_at, end_types) do
    do_parse_until(expression, parsers, tokens, start_at, end_types, start_at, [])
  end

  defp do_parse_until(expression, parsers, tokens, start_at, end_types, current, acc) do
    if current >= tuple_size(tokens) or looking_at_any(tokens, current, end_types) do
      {:ok, current - start_at, Enum.reverse(acc)}
    else
      case parse_token(expression, parsers, tokens, current) do
        {:error, _} = error ->
          error

        {:ok, consumed, node} when consumed > 0 ->
          do_parse_until(expression, parsers, tokens, start_at, end_types, current + consumed, [
            node | acc
          ])

        {:ok, 0, _} ->
          # If configured correctly this will never happen. Keep to avoid infinite loops.
          {:error, %Error{type: :no_eligible_parsers, message: "No eligible parsers"}}
      end
    end
  end

  defp parse_token(_expression, [], _tokens, _current) do
    # If configured correctly this will never happen
    {:error, %Error{message: "No eligible parsers"}}
  end

  defp parse_token(expression, [parser | rest], tokens, current) do
    case parser.(expression, tokens, current) do
      {:error, _} = error -> error
      {:ok, 0, _} -> parse_token(expression, rest, tokens, current)
      {:ok, _, _} = result -> result
    end
  end

  defp looking_at(tokens, at, type) do
    cond do
      at < 0 -> type == :start_of_line
      at >= tuple_size(tokens) -> type == :end_of_line
      true -> elem(tokens, at).type == type
    end
  end

  defp looking_at_any(tokens, at, types), do: Enum.any?(types, &looking_at(tokens, at, &1))

  defp split_alternatives(start, end_, nodes) do
    {separators, alternatives, current} =
      Enum.reduce(nodes, {[], [], []}, fn node, {separators, alternatives, current} ->
        if node.type == :alternative_node do
          {[node | separators], [Enum.reverse(current) | alternatives], []}
        else
          {separators, alternatives, [node | current]}
        end
      end)

    separators = Enum.reverse(separators)
    alternatives = Enum.reverse([Enum.reverse(current) | alternatives])
    create_alternative_nodes(start, end_, separators, alternatives)
  end

  defp create_alternative_nodes(start, end_, separators, alternatives) do
    last = length(alternatives) - 1

    alternatives
    |> Enum.with_index()
    |> Enum.map(fn {children, i} ->
      {alt_start, alt_end} =
        cond do
          i == 0 -> {start, Enum.at(separators, i).start}
          i == last -> {Enum.at(separators, i - 1).end, end_}
          true -> {Enum.at(separators, i - 1).end, Enum.at(separators, i).start}
        end

      %Node{type: :alternative_node, start: alt_start, end: alt_end, nodes: children}
    end)
  end
end
