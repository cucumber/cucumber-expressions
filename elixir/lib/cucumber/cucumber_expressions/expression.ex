defprotocol Cucumber.CucumberExpressions.Expression do
  @moduledoc """
  The common interface of `Cucumber.CucumberExpressions.CucumberExpression` and
  `Cucumber.CucumberExpressions.RegularExpression`, so both can be held and
  matched uniformly.
  """

  @doc """
  Matches `text`, returning a list of `Cucumber.CucumberExpressions.Argument`s or
  `nil` if the text does not match.
  """
  def match(expression, text)

  @doc "The compiled `Regex`."
  def regexp(expression)

  @doc "The expression's source string."
  def source(expression)
end

defimpl Cucumber.CucumberExpressions.Expression,
  for: Cucumber.CucumberExpressions.CucumberExpression do
  alias Cucumber.CucumberExpressions.CucumberExpression

  def match(expression, text), do: CucumberExpression.match(expression, text)
  def regexp(expression), do: CucumberExpression.regexp(expression)
  def source(expression), do: expression.source
end

defimpl Cucumber.CucumberExpressions.Expression,
  for: Cucumber.CucumberExpressions.RegularExpression do
  alias Cucumber.CucumberExpressions.RegularExpression

  def match(expression, text), do: RegularExpression.match(expression, text)
  def regexp(expression), do: RegularExpression.regexp(expression)
  def source(expression), do: RegularExpression.source(expression)
end
