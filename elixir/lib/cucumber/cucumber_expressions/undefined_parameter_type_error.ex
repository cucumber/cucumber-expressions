defmodule Cucumber.CucumberExpressions.UndefinedParameterTypeError do
  @moduledoc """
  Error for a `{parameter}` reference whose name is not registered in the
  `Cucumber.CucumberExpressions.ParameterTypeRegistry`.
  """

  alias Cucumber.CucumberExpressions.Error

  defexception [:message, :undefined_parameter_type_name]

  @type t :: %__MODULE__{message: String.t(), undefined_parameter_type_name: String.t()}

  @doc false
  def new(expression, node, type_name) do
    %__MODULE__{
      undefined_parameter_type_name: type_name,
      message:
        Error.format_message(
          expression,
          node,
          "Undefined parameter type '#{type_name}'",
          "Please register a ParameterType for '#{type_name}'"
        )
    }
  end
end
