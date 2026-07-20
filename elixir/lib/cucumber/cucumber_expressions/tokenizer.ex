defmodule Cucumber.CucumberExpressions.Tokenizer do
  @moduledoc """
  Splits a Cucumber Expression source string into a list of
  `Cucumber.CucumberExpressions.Token`s.
  """

  alias Cucumber.CucumberExpressions.{Error, Token}

  @spec tokenize(String.t()) :: {:ok, [Token.t()]} | {:error, Error.t()}
  def tokenize(expression) do
    codepoints = String.to_charlist(expression)

    state = %{
      tokens: initial_tokens(codepoints),
      buffer: [],
      buffer_start: 0,
      previous: :start_of_line,
      treat_as_text: false,
      escaped: 0
    }

    loop(codepoints, expression, length(codepoints), state)
  end

  @spec tokenize!(String.t()) :: [Token.t()]
  def tokenize!(expression) do
    case tokenize(expression) do
      {:ok, tokens} -> tokens
      {:error, error} -> raise error
    end
  end

  defp initial_tokens([]), do: [%Token{type: :start_of_line, text: "", start: 0, end: 0}]
  defp initial_tokens(_), do: []

  defp loop([codepoint | rest], expression, total, %{treat_as_text: false} = state)
       when codepoint == ?\\ do
    loop(rest, expression, total, %{state | escaped: state.escaped + 1, treat_as_text: true})
  end

  defp loop([codepoint | rest], expression, total, state) do
    case token_type_of(codepoint, state, expression) do
      {:error, _} = error ->
        error

      {:ok, current} ->
        state = %{state | treat_as_text: false}

        state =
          if new_token?(current, state.previous) do
            {token, state} = flush(state, state.previous)
            %{state | tokens: [token | state.tokens], previous: current, buffer: [codepoint]}
          else
            %{state | previous: current, buffer: [codepoint | state.buffer]}
          end

        loop(rest, expression, total, state)
    end
  end

  defp loop([], expression, total, state) do
    state =
      if state.buffer == [] do
        state
      else
        {token, state} = flush(state, state.previous)
        %{state | tokens: [token | state.tokens]}
      end

    if state.treat_as_text do
      {:error, Error.end_of_line_can_not_be_escaped(expression)}
    else
      end_of_line = %Token{type: :end_of_line, text: "", start: total, end: total}
      {:ok, Enum.reverse([end_of_line | state.tokens])}
    end
  end

  defp token_type_of(codepoint, %{treat_as_text: false}, _expression) do
    {:ok, Token.type_of(codepoint)}
  end

  defp token_type_of(codepoint, %{treat_as_text: true} = state, expression) do
    if Token.can_escape?(codepoint) do
      {:ok, :text}
    else
      index = state.buffer_start + length(state.buffer) + state.escaped
      {:error, Error.cant_escape(expression, index)}
    end
  end

  defp new_token?(current, previous) do
    current != previous or (current != :white_space and current != :text)
  end

  defp flush(%{buffer: buffer, buffer_start: start, escaped: escaped} = state, type) do
    escape_tokens = if type == :text, do: escaped, else: 0
    consumed = start + length(buffer) + escape_tokens

    token = %Token{
      type: type,
      text: List.to_string(Enum.reverse(buffer)),
      start: start,
      end: consumed
    }

    escaped = if type == :text, do: 0, else: escaped
    {token, %{state | buffer: [], buffer_start: consumed, escaped: escaped}}
  end
end
