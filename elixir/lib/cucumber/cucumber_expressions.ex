defmodule Cucumber.CucumberExpressions do
  @moduledoc """
  Cucumber Expressions — a simpler alternative to Regular Expressions.

  This is the Elixir port of [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions),
  verified against the language-neutral `testdata` conformance corpus shared by
  all the ports.

      iex> alias Cucumber.CucumberExpressions, as: CE
      iex> registry = CE.ParameterTypeRegistry.new()
      iex> {:ok, expression} = CE.compile("I have {int} cuke(s)", registry)
      iex> expression |> CE.Expression.match("I have 7 cukes") |> Enum.map(&CE.Argument.value/1)
      [7]

  `compile/2` creates a `CucumberExpression` from a string and a
  `RegularExpression` from a `Regex` — the same dispatch Cucumber applies to
  step definition patterns.
  """

  alias Cucumber.CucumberExpressions.{
    CucumberExpression,
    ParameterTypeRegistry,
    RegularExpression
  }

  @type expression :: CucumberExpression.t() | RegularExpression.t()

  @doc """
  Compiles a step definition pattern: a string becomes a
  `Cucumber.CucumberExpressions.CucumberExpression`, a `Regex` becomes a
  `Cucumber.CucumberExpressions.RegularExpression`.
  """
  @spec compile(String.t() | Regex.t(), ParameterTypeRegistry.t()) ::
          {:ok, expression()} | {:error, Exception.t()}
  def compile(%Regex{} = regexp, %ParameterTypeRegistry{} = registry) do
    RegularExpression.compile(regexp, registry)
  end

  def compile(source, %ParameterTypeRegistry{} = registry) when is_binary(source) do
    CucumberExpression.compile(source, registry)
  end

  @spec compile!(String.t() | Regex.t(), ParameterTypeRegistry.t()) :: expression()
  def compile!(pattern, %ParameterTypeRegistry{} = registry) do
    case compile(pattern, registry) do
      {:ok, expression} -> expression
      {:error, error} -> raise error
    end
  end
end
