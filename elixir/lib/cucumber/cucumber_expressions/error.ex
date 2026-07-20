defmodule Cucumber.CucumberExpressions.Error do
  @moduledoc """
  Error raised (or returned as `{:error, %Error{}}`) when a Cucumber Expression
  is invalid.

  Messages are byte-for-byte identical to the other language ports — they are
  part of the conformance surface verified by the shared testdata. For
  programmatic handling, match on `type` (a stable atom) rather than the
  message string: `{:error, %Error{type: :optional_may_not_be_empty}}`.
  """

  defexception [:message, :type]

  alias Cucumber.CucumberExpressions.Token

  @typedoc "A stable identifier for the kind of problem, safe to pattern-match on."
  @type error_type ::
          :cant_escape
          | :end_of_line_cannot_be_escaped
          | :missing_end_token
          | :alternation_not_allowed_in_optional
          | :invalid_parameter_type_name
          | :optional_may_not_be_empty
          | :parameter_is_not_allowed_in_optional
          | :optional_is_not_allowed_in_optional
          | :alternative_may_not_be_empty
          | :alternative_may_not_exclusively_contain_optionals
          | :parameter_type_regexps_cannot_use_flags
          | :invalid_parameter_type_regexp
          | :invalid_regexp
          | :duplicate_parameter_type_name
          | :anonymous_parameter_type_already_defined
          | :duplicate_preferential_parameter_type

  @type t :: %__MODULE__{message: String.t(), type: error_type() | nil}

  @doc false
  def cant_escape(expression, index) do
    build(
      :cant_escape,
      index,
      expression,
      point_at(index),
      "Only the characters '{', '}', '(', ')', '\\', '/' and whitespace can be escaped",
      "If you did mean to use an '\\' you can use '\\\\' to escape it"
    )
  end

  @doc false
  def end_of_line_cannot_be_escaped(expression) do
    index = String.length(expression) - 1

    build(
      :end_of_line_cannot_be_escaped,
      index,
      expression,
      point_at(index),
      "The end of line can not be escaped",
      "You can use '\\\\' to escape the '\\'"
    )
  end

  @doc false
  def missing_end_token(expression, begin_type, end_type, %Token{start: start} = current) do
    build(
      :missing_end_token,
      start,
      expression,
      point_at_located(current),
      "The '#{Token.symbol_of(begin_type)}' does not have a matching '#{Token.symbol_of(end_type)}'",
      "If you did not intend to use #{Token.purpose_of(begin_type)} you can use " <>
        "'\\#{Token.symbol_of(begin_type)}' to escape the #{Token.purpose_of(begin_type)}"
    )
  end

  @doc false
  def alternation_not_allowed_in_optional(expression, %Token{start: start} = current) do
    build(
      :alternation_not_allowed_in_optional,
      start,
      expression,
      point_at_located(current),
      "An alternation can not be used inside an optional",
      "If you did not mean to use an alternation you can use '\\/' to escape the '/'. " <>
        "Otherwise rephrase your expression or consider using a regular expression instead."
    )
  end

  @doc false
  def invalid_parameter_type_name_in_node(expression, %Token{start: start} = token) do
    build(
      :invalid_parameter_type_name,
      start,
      expression,
      point_at_located(token),
      "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'",
      "Did you mean to use a regular expression?"
    )
  end

  @doc false
  def optional_may_not_be_empty(expression, node) do
    build_at(
      :optional_may_not_be_empty,
      expression,
      node,
      "An optional must contain some text",
      "If you did not mean to use an optional you can use '\\(' to escape the '('"
    )
  end

  @doc false
  def parameter_is_not_allowed_in_optional(expression, node) do
    build_at(
      :parameter_is_not_allowed_in_optional,
      expression,
      node,
      "An optional may not contain a parameter type",
      "If you did not mean to use an parameter type you can use '\\{' to escape the '{'"
    )
  end

  @doc false
  def optional_is_not_allowed_in_optional(expression, node) do
    build_at(
      :optional_is_not_allowed_in_optional,
      expression,
      node,
      "An optional may not contain an other optional",
      "If you did not mean to use an optional type you can use '\\(' to escape the '('. " <>
        "For more complicated expressions consider using a regular expression instead."
    )
  end

  @doc false
  def alternative_may_not_be_empty(expression, node) do
    build_at(
      :alternative_may_not_be_empty,
      expression,
      node,
      "Alternative may not be empty",
      "If you did not mean to use an alternative you can use '\\/' to escape the '/'"
    )
  end

  @doc false
  def alternative_may_not_exclusively_contain_optionals(expression, node) do
    build_at(
      :alternative_may_not_exclusively_contain_optionals,
      expression,
      node,
      "An alternative may not exclusively contain optionals",
      "If you did not mean to use an optional you can use '\\(' to escape the '('"
    )
  end

  @doc false
  def invalid_parameter_type_name(type_name) do
    %__MODULE__{
      type: :invalid_parameter_type_name,
      message:
        "Illegal character in parameter name {#{type_name}}. " <>
          "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'"
    }
  end

  @doc """
  Builds an error whose message points at a location in the expression.

  `located` is anything with `start` and `end` fields (a token or an AST node).
  """
  def build_at(type, expression, located, problem, solution) do
    build(type, located.start, expression, point_at_located(located), problem, solution)
  end

  @doc """
  Formats the standard problem-pointer message used by all located errors.
  """
  def format_message(expression, located, problem, solution) do
    format(located.start, expression, point_at_located(located), problem, solution)
  end

  defp build(type, index, expression, pointer, problem, solution) do
    %__MODULE__{type: type, message: format(index, expression, pointer, problem, solution)}
  end

  defp format(index, expression, pointer, problem, solution) do
    "This Cucumber Expression has a problem at column #{index + 1}:\n" <>
      "\n" <>
      expression <>
      "\n" <>
      pointer <>
      "\n" <>
      problem <>
      ".\n" <>
      solution
  end

  defp point_at(index), do: String.duplicate(" ", index) <> "^"

  defp point_at_located(%{start: start, end: end_} = _located) do
    pointer = point_at(start)

    if start + 1 < end_ do
      pointer <> String.duplicate("-", end_ - start - 2) <> "^"
    else
      pointer
    end
  end
end
