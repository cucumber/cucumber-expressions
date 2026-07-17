defmodule Varar.CucumberExpressions.Argument do
  @moduledoc """
  A matched argument: a capture group paired with the parameter type that
  transforms it. `value/1` produces the transformed value.
  """

  alias Varar.CucumberExpressions.{Error, Group, ParameterType, TreeRegexp}

  @enforce_keys [:group, :parameter_type]
  defstruct [:group, :parameter_type]

  @type t :: %__MODULE__{group: Group.t(), parameter_type: ParameterType.t()}

  @doc """
  Matches `text` against `tree_regexp` and pairs each top-level capture group
  with its parameter type. Returns `nil` if the text does not match. Raises
  `Varar.CucumberExpressions.Error` if the number of capture groups does not
  match the number of parameter types.
  """
  @spec build(TreeRegexp.t(), String.t(), [ParameterType.t()]) :: [t()] | nil
  def build(tree_regexp, text, parameter_types) do
    case TreeRegexp.match(tree_regexp, text) do
      nil ->
        nil

      group ->
        arg_groups = group.children || []

        if length(arg_groups) != length(parameter_types) do
          raise Error,
            message:
              "Expression /#{Regex.source(tree_regexp.regex)}/ has #{length(arg_groups)} " <>
                "capture groups (#{inspect(Enum.map(arg_groups, & &1.value))}), " <>
                "but there were #{length(parameter_types)} parameter types " <>
                "(#{inspect(Enum.map(parameter_types, & &1.name))})"
        end

        Enum.zip_with(parameter_types, arg_groups, fn parameter_type, arg_group ->
          %__MODULE__{group: arg_group, parameter_type: parameter_type}
        end)
    end
  end

  @doc "The transformed value of this argument."
  def value(%__MODULE__{group: group, parameter_type: parameter_type}) do
    ParameterType.transform(parameter_type, group && Group.values(group))
  end
end
