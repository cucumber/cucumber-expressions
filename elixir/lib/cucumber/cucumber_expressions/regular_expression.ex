defmodule Cucumber.CucumberExpressions.RegularExpression do
  @moduledoc """
  A plain Regular Expression whose capture groups are transformed with the
  parameter types whose regexps match the group sources — the same behaviour
  Cucumber applies to classic regexp step definitions.
  """

  alias Cucumber.CucumberExpressions.{
    Argument,
    Error,
    ParameterType,
    ParameterTypeRegistry,
    TreeRegexp
  }

  @enforce_keys [:tree_regexp, :parameter_type_registry]
  defstruct [:tree_regexp, :parameter_type_registry]

  @type t :: %__MODULE__{
          tree_regexp: TreeRegexp.t(),
          parameter_type_registry: ParameterTypeRegistry.t()
        }

  @spec compile(Regex.t() | String.t(), ParameterTypeRegistry.t()) ::
          {:ok, t()} | {:error, Error.t()}
  def compile(regexp, %ParameterTypeRegistry{} = registry) do
    {:ok, compile!(regexp, registry)}
  rescue
    error in [Error] ->
      {:error, error}

    error in [Regex.CompileError] ->
      {:error, %Error{type: :invalid_regexp, message: Exception.message(error)}}
  end

  @spec compile!(Regex.t() | String.t(), ParameterTypeRegistry.t()) :: t()
  def compile!(regexp, %ParameterTypeRegistry{} = registry) do
    %__MODULE__{tree_regexp: TreeRegexp.new!(regexp), parameter_type_registry: registry}
  end

  @doc """
  Matches `text`. Returns a list of `Cucumber.CucumberExpressions.Argument`s or
  `nil` if the text does not match. Raises
  `Cucumber.CucumberExpressions.AmbiguousParameterTypeError` if a capture group's
  regexp is used by several parameter types and none is preferential.
  """
  @spec match(t(), String.t()) :: [Argument.t()] | nil
  def match(%__MODULE__{tree_regexp: tree_regexp, parameter_type_registry: registry}, text) do
    parameter_types =
      Enum.map(tree_regexp.group_builder.children, fn group_builder ->
        ParameterTypeRegistry.lookup_by_regexp(
          registry,
          group_builder.source,
          Regex.source(tree_regexp.regexp),
          text
        ) ||
          ParameterType.new!(
            name: nil,
            regexps: group_builder.source,
            type: :string,
            use_for_snippets: false,
            prefer_for_regexp_match: false
          )
      end)

    Argument.build(tree_regexp, text, parameter_types)
  end

  @doc "The underlying `Regex`."
  @spec regexp(t()) :: Regex.t()
  def regexp(%__MODULE__{tree_regexp: tree_regexp}), do: tree_regexp.regexp

  @doc "The regexp source string."
  @spec source(t()) :: String.t()
  def source(%__MODULE__{tree_regexp: tree_regexp}), do: Regex.source(tree_regexp.regexp)
end
