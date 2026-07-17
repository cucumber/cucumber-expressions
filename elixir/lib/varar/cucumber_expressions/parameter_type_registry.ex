defmodule Varar.CucumberExpressions.ParameterTypeRegistry do
  @moduledoc """
  An immutable registry of `Varar.CucumberExpressions.ParameterType`s.

  `new/0` returns a registry with the built-in types (`{int}`, `{float}`,
  `{word}`, `{string}`, the anonymous `{}`, `{bigdecimal}`, `{biginteger}`,
  `{byte}`, `{short}`, `{long}` and `{double}`). Custom types are added with
  `add/2`, which returns a new registry — thread the value through your code.
  """

  alias Varar.CucumberExpressions.{Error, ParameterType}

  defstruct by_name: %{}, by_regexp: %{}, order: []

  @type t :: %__MODULE__{
          by_name: %{optional(String.t()) => ParameterType.t()},
          by_regexp: %{optional(String.t()) => [ParameterType.t()]},
          order: [String.t()]
        }

  @integer_regexps ["-?\\d+", "\\d+"]
  @float_regexp "(?=.*\\d.*)[-+]?\\d*(?:\\.(?=\\d.*))?\\d*(?:\\d+[E][-+]?\\d+)?"
  @word_regexp "[^\\s]+"
  @string_regexp "\"([^\"\\\\]*(\\\\.[^\"\\\\]*)*)\"|'([^'\\\\]*(\\\\.[^'\\\\]*)*)'"
  @anonymous_regexp ".*"

  @doc "Creates a registry containing the built-in parameter types."
  @spec new() :: t()
  def new do
    builtins = [
      [
        name: "int",
        regexps: @integer_regexps,
        type: :integer,
        transformer: &__MODULE__.to_integer/1,
        use_for_snippets: true,
        prefer_for_regexp_match: true
      ],
      [
        name: "float",
        regexps: @float_regexp,
        type: :float,
        transformer: &__MODULE__.to_float/1,
        use_for_snippets: true,
        prefer_for_regexp_match: false
      ],
      [
        name: "word",
        regexps: @word_regexp,
        type: :string,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "string",
        regexps: @string_regexp,
        type: :string,
        transformer: &__MODULE__.unescape_string/2,
        use_for_snippets: true,
        prefer_for_regexp_match: false
      ],
      [
        name: "",
        regexps: @anonymous_regexp,
        type: :string,
        use_for_snippets: false,
        prefer_for_regexp_match: true
      ],
      [
        name: "bigdecimal",
        regexps: @float_regexp,
        type: :decimal,
        transformer: &__MODULE__.to_decimal/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "biginteger",
        regexps: @integer_regexps,
        type: :integer,
        transformer: &__MODULE__.to_integer/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "byte",
        regexps: @integer_regexps,
        type: :integer,
        transformer: &__MODULE__.to_integer/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "short",
        regexps: @integer_regexps,
        type: :integer,
        transformer: &__MODULE__.to_integer/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "long",
        regexps: @integer_regexps,
        type: :integer,
        transformer: &__MODULE__.to_integer/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ],
      [
        name: "double",
        regexps: @float_regexp,
        type: :float,
        transformer: &__MODULE__.to_float/1,
        use_for_snippets: false,
        prefer_for_regexp_match: false
      ]
    ]

    Enum.reduce(builtins, %__MODULE__{}, fn options, registry ->
      add!(registry, ParameterType.new!(options))
    end)
  end

  @doc "Looks up a parameter type by the name used inside `{...}`."
  @spec lookup_by_type_name(t(), String.t()) :: ParameterType.t() | nil
  def lookup_by_type_name(%__MODULE__{by_name: by_name}, name), do: Map.get(by_name, name)

  @doc "All registered parameter types, in registration order."
  @spec parameter_types(t()) :: [ParameterType.t()]
  def parameter_types(%__MODULE__{by_name: by_name, order: order}) do
    Enum.map(order, &Map.fetch!(by_name, &1))
  end

  @doc """
  Looks up the parameter type for a Regular Expression capture group's source.

  Returns `nil` when no type uses that regexp. Raises
  `Varar.CucumberExpressions.AmbiguousParameterTypeError` when several types
  use it and none is preferential.
  """
  def lookup_by_regexp(%__MODULE__{} = registry, parameter_type_regexp, expression_regexp, text) do
    case Map.get(registry.by_regexp, parameter_type_regexp, []) do
      [] ->
        nil

      [first | rest] = parameter_types ->
        if rest != [] and not first.prefer_for_regexp_match do
          # We don't do this check on insertion because we only want to restrict
          # ambiguity when we look up by regexp. Users of CucumberExpression
          # should not be restricted.
          generated_expressions =
            Varar.CucumberExpressions.Generator.generate_expressions(registry, text)

          raise Varar.CucumberExpressions.AmbiguousParameterTypeError.new(
                  parameter_type_regexp,
                  expression_regexp,
                  parameter_types,
                  generated_expressions
                )
        end

        first
    end
  end

  @doc """
  Returns a new registry with `parameter_type` added, or an error if the name
  is taken or another preferential type uses one of the same regexps.
  """
  @spec add(t(), ParameterType.t()) :: {:ok, t()} | {:error, Error.t()}
  def add(%__MODULE__{} = registry, %ParameterType{} = parameter_type) do
    with {:ok, registry} <- add_by_name(registry, parameter_type) do
      add_by_regexps(registry, parameter_type)
    end
  end

  @spec add!(t(), ParameterType.t()) :: t()
  def add!(%__MODULE__{} = registry, %ParameterType{} = parameter_type) do
    case add(registry, parameter_type) do
      {:ok, registry} -> registry
      {:error, error} -> raise error
    end
  end

  defp add_by_name(registry, %ParameterType{name: nil}), do: {:ok, registry}

  defp add_by_name(registry, %ParameterType{name: name} = parameter_type) do
    cond do
      not Map.has_key?(registry.by_name, name) ->
        {:ok,
         %{
           registry
           | by_name: Map.put(registry.by_name, name, parameter_type),
             order: registry.order ++ [name]
         }}

      name == "" ->
        {:error, %Error{message: "The anonymous parameter type has already been defined"}}

      true ->
        {:error, %Error{message: "There is already a parameter with name #{name}"}}
    end
  end

  defp add_by_regexps(registry, parameter_type) do
    Enum.reduce_while(parameter_type.regexps, {:ok, registry}, fn regexp, {:ok, registry} ->
      existing = Map.get(registry.by_regexp, regexp, [])

      case existing do
        [%ParameterType{prefer_for_regexp_match: true} = first | _]
        when parameter_type.prefer_for_regexp_match ->
          {:halt,
           {:error,
            %Error{
              message:
                "There can only be one preferential parameter type per regexp. " <>
                  "The regexp /#{regexp}/ is used for two: {#{first.name}} and {#{parameter_type.name}}"
            }}}

        _ ->
          sorted = Enum.sort([parameter_type | existing], &ParameterType.compare/2)
          {:cont, {:ok, %{registry | by_regexp: Map.put(registry.by_regexp, regexp, sorted)}}}
      end
    end)
  end

  @doc false
  def to_integer(nil), do: nil
  def to_integer(string), do: String.to_integer(string)

  @doc false
  def to_float(nil), do: nil

  def to_float(string) do
    normalized = Regex.replace(~r/^([+-]?)\./, string, "\\g{1}0.")

    case Float.parse(normalized) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  @doc false
  def to_decimal(nil), do: nil

  # Builds the %Decimal{} directly: Decimal.new/1 caps the number of digits it
  # parses (a DoS guard added in decimal 3.x), but {bigdecimal} must accept
  # arbitrary precision.
  def to_decimal(string) do
    {sign, rest} =
      case string do
        "-" <> rest -> {-1, rest}
        "+" <> rest -> {1, rest}
        rest -> {1, rest}
      end

    {mantissa, exponent} =
      case String.split(rest, ~r/[eE]/, parts: 2) do
        [mantissa] -> {mantissa, 0}
        [mantissa, exponent] -> {mantissa, String.to_integer(exponent)}
      end

    {int_part, frac_part} =
      case String.split(mantissa, ".", parts: 2) do
        [int_part] -> {int_part, ""}
        [int_part, frac_part] -> {int_part, frac_part}
      end

    digits = int_part <> frac_part

    %Decimal{
      sign: sign,
      coef: String.to_integer(if digits == "", do: "0", else: digits),
      exp: exponent - String.length(frac_part)
    }
  end

  @doc false
  def unescape_string(double_quoted, single_quoted) do
    (double_quoted || single_quoted)
    |> String.replace("\\\"", "\"")
    |> String.replace("\\'", "'")
  end
end
