defmodule Varar.CucumberExpressions.Generator do
  @moduledoc """
  Generates Cucumber Expression suggestions for a given text.
  """

  alias Varar.CucumberExpressions.ParameterTypeRegistry

  @doc """
  Generates suggested expressions for `text`, most specific first.
  """
  def generate_expressions(%ParameterTypeRegistry{} = _registry, _text) do
    # Implemented with the generator milestone.
    []
  end
end
