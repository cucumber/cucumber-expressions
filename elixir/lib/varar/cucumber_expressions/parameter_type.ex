defmodule Varar.CucumberExpressions.ParameterType do
  @moduledoc """
  A parameter type — the definition behind a `{name}` reference in a
  Cucumber Expression.

  * `name` — the name used inside `{...}`. `""` is the anonymous type; `nil`
    means the type cannot be referenced by name.
  * `regexps` — a list of regexp source strings; each becomes a capture group
    alternative.
  * `type` — a tag describing the transformed value's type (used for
    documentation and snippet generation), e.g. `:integer` or `:string`.
  * `transformer` — a function receiving as many captured group strings as its
    arity; its result is the argument value.
  * `use_for_snippets` — whether the generator suggests this type for snippets.
  * `prefer_for_regexp_match` — whether this type wins when several types share
    a regexp.
  """

  alias Varar.CucumberExpressions.Error

  @enforce_keys [:name, :regexps]
  defstruct [
    :name,
    :regexps,
    type: :string,
    transformer: &Function.identity/1,
    use_for_snippets: true,
    prefer_for_regexp_match: false
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          regexps: [String.t()],
          type: term(),
          transformer: fun(),
          use_for_snippets: boolean(),
          prefer_for_regexp_match: boolean()
        }

  @illegal_name_pattern ~r/([\[\]()$.|?*+])/
  @unescape_pattern ~r/(\\([\[$.|?*+\]]))/

  @doc """
  Creates a parameter type from a keyword list; see the module doc for the
  meaning of each option. `:name` and `:regexps` are required. `:regexps`
  accepts a single source string, `Regex`, or a list of either.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(options) do
    name = Keyword.fetch!(options, :name)
    regexps = options |> Keyword.fetch!(:regexps) |> List.wrap()

    with :ok <- check_parameter_type_name(name),
         {:ok, sources} <- regexp_sources(regexps) do
      {:ok,
       %__MODULE__{
         name: name,
         regexps: sources,
         type: Keyword.get(options, :type, :string),
         transformer: Keyword.get(options, :transformer, &Function.identity/1),
         use_for_snippets: Keyword.get(options, :use_for_snippets, true),
         prefer_for_regexp_match: Keyword.get(options, :prefer_for_regexp_match, false)
       }}
    end
  end

  @spec new!(keyword()) :: t()
  def new!(options) do
    case new(options) do
      {:ok, parameter_type} -> parameter_type
      {:error, error} -> raise error
    end
  end

  @doc "Validates a parameter type name, as `new/1` does."
  @spec check_parameter_type_name(String.t() | nil) :: :ok | {:error, Error.t()}
  def check_parameter_type_name(nil), do: :ok

  def check_parameter_type_name(type_name) do
    if valid_parameter_type_name?(type_name) do
      :ok
    else
      {:error, Error.invalid_parameter_type_name(type_name)}
    end
  end

  @doc false
  def valid_parameter_type_name?(type_name) do
    unescaped = Regex.replace(@unescape_pattern, type_name, "\\2")
    not Regex.match?(@illegal_name_pattern, unescaped)
  end

  @doc "Whether this is the anonymous parameter type (empty name)."
  def anonymous?(%__MODULE__{name: name}), do: name == ""

  @doc """
  Transforms captured group strings into the argument value by calling the
  transformer with as many leading group values as its arity.
  """
  def transform(%__MODULE__{transformer: transformer}, group_values) do
    {:arity, arity} = Function.info(transformer, :arity)
    values = group_values || []
    padded = values ++ List.duplicate(nil, max(arity - length(values), 0))
    apply(transformer, Enum.take(padded, arity))
  end

  @doc """
  Compares two parameter types: preferential types first, then by name.
  Returns `true` if `left` sorts before (or equal to) `right`, for use with
  `Enum.sort/2`.
  """
  def compare(%__MODULE__{} = left, %__MODULE__{} = right) do
    cond do
      left.prefer_for_regexp_match and not right.prefer_for_regexp_match -> true
      right.prefer_for_regexp_match and not left.prefer_for_regexp_match -> false
      true -> (left.name || "") <= (right.name || "")
    end
  end

  defp regexp_sources(regexps) do
    Enum.reduce_while(regexps, {:ok, []}, fn regexp, {:ok, acc} ->
      case regexp_source(regexp) do
        {:ok, source} -> {:cont, {:ok, acc ++ [source]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp regexp_source(source) when is_binary(source), do: {:ok, source}

  defp regexp_source(%Regex{} = regexp) do
    if unicode_only_opts?(Regex.opts(regexp)) do
      {:ok, Regex.source(regexp)}
    else
      {:error, %Error{message: "ParameterType Regexps can't use flags"}}
    end
  end

  # Regex.opts/1 returns an atom list on recent Elixir versions and a string
  # of modifiers on older ones; the string clause is unreachable on the
  # version Dialyzer runs under.
  @dialyzer {:no_match, unicode_only_opts?: 1}
  defp unicode_only_opts?(opts) when is_list(opts), do: opts -- [:unicode, :ucp] == []
  defp unicode_only_opts?(opts) when is_binary(opts), do: opts in ["", "u"]
end
