defmodule Varar.CucumberExpressions.AmbiguousParameterTypeError do
  @moduledoc """
  Error raised when a Regular Expression capture group's regexp matches
  several parameter types and none of them is preferential.
  """

  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}

  @doc false
  def new(parameter_type_regexp, expression_regexp_source, parameter_types, generated_expressions) do
    parameter_type_names = Enum.map_join(parameter_types, "\n   ", &"{#{&1.name}}")

    generated_sources =
      Enum.map_join(generated_expressions, "\n   ", & &1.source)

    %__MODULE__{
      message: """
      Your Regular Expression /#{expression_regexp_source}/
      matches multiple parameter types with regexp /#{parameter_type_regexp}/:
         #{parameter_type_names}

      I couldn't decide which one to use. You have two options:

      1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:
         #{generated_sources}

      2) Make one of the parameter types preferential and continue to use a Regular Expression.

      """
    }
  end
end
