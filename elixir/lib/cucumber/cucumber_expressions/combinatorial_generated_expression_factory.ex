defmodule Cucumber.CucumberExpressions.CombinatorialGeneratedExpressionFactory do
  @moduledoc false

  alias Cucumber.CucumberExpressions.GeneratedExpression

  # 256 generated expressions ought to be enough for anybody
  @max_expressions 256

  @doc """
  Generates one expression per combination of the parameter type choices for
  each placeholder, capped at #{@max_expressions}.
  """
  def generate_expressions(expression_template, parameter_type_combinations) do
    parameter_type_combinations
    |> Enum.reduce([[]], fn parameter_types, prefixes ->
      prefixes
      |> Enum.flat_map(fn prefix -> Enum.map(parameter_types, &(prefix ++ [&1])) end)
      |> Enum.take(@max_expressions)
    end)
    |> Enum.map(&GeneratedExpression.new(expression_template, &1))
  end
end
