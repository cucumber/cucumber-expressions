defmodule Varar.CucumberExpressions.Token do
  @moduledoc """
  A token produced by `Varar.CucumberExpressions.Tokenizer`.

  `start` and `end` are codepoint offsets into the expression source, matching
  the language-neutral testdata convention.
  """

  @enforce_keys [:type, :text, :start, :end]
  defstruct [:type, :text, :start, :end]

  @type type ::
          :start_of_line
          | :end_of_line
          | :white_space
          | :begin_optional
          | :end_optional
          | :begin_parameter
          | :end_parameter
          | :alternation
          | :text

  @type t :: %__MODULE__{
          type: type(),
          text: String.t(),
          start: non_neg_integer(),
          end: non_neg_integer()
        }

  @escape_character ?\\
  @alternation_character ?/
  @begin_parameter_character ?{
  @end_parameter_character ?}
  @begin_optional_character ?(
  @end_optional_character ?)

  @type_strings %{
    start_of_line: "START_OF_LINE",
    end_of_line: "END_OF_LINE",
    white_space: "WHITE_SPACE",
    begin_optional: "BEGIN_OPTIONAL",
    end_optional: "END_OPTIONAL",
    begin_parameter: "BEGIN_PARAMETER",
    end_parameter: "END_PARAMETER",
    alternation: "ALTERNATION",
    text: "TEXT"
  }

  @whitespace ~r/\s/u

  @doc "The upstream string name of a token type, e.g. `\"START_OF_LINE\"`."
  def type_string(type), do: Map.fetch!(@type_strings, type)

  def escape_character?(codepoint), do: codepoint == @escape_character

  def whitespace?(codepoint), do: String.match?(<<codepoint::utf8>>, @whitespace)

  @doc "Whether a codepoint may legally follow an escape character."
  def can_escape?(codepoint) do
    codepoint in [
      @escape_character,
      @alternation_character,
      @begin_parameter_character,
      @end_parameter_character,
      @begin_optional_character,
      @end_optional_character
    ] or whitespace?(codepoint)
  end

  @doc "The token type of an unescaped codepoint."
  def type_of(codepoint) do
    cond do
      whitespace?(codepoint) -> :white_space
      codepoint == @alternation_character -> :alternation
      codepoint == @begin_parameter_character -> :begin_parameter
      codepoint == @end_parameter_character -> :end_parameter
      codepoint == @begin_optional_character -> :begin_optional
      codepoint == @end_optional_character -> :end_optional
      true -> :text
    end
  end

  @doc "The literal character for a token type, used in error messages."
  def symbol(:begin_optional), do: "("
  def symbol(:end_optional), do: ")"
  def symbol(:begin_parameter), do: "{"
  def symbol(:end_parameter), do: "}"
  def symbol(:alternation), do: "/"
  def symbol(_), do: ""

  @doc "The human-readable purpose of a token type, used in error messages."
  def purpose(:begin_optional), do: "optional text"
  def purpose(:end_optional), do: "optional text"
  def purpose(:begin_parameter), do: "a parameter"
  def purpose(:end_parameter), do: "a parameter"
  def purpose(:alternation), do: "alternation"
  def purpose(_), do: ""
end
