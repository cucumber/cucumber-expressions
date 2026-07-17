defprotocol Varar.CucumberExpressions.Expression do
  @moduledoc """
  The common interface of `Varar.CucumberExpressions.CucumberExpression` and
  `Varar.CucumberExpressions.RegularExpression`, so both can be held and
  matched uniformly.
  """

  @doc """
  Matches `text`, returning a list of `Varar.CucumberExpressions.Argument`s or
  `nil` if the text does not match.
  """
  def match(expression, text)

  @doc "The compiled `Regex`."
  def regex(expression)

  @doc "The expression's source string."
  def source(expression)
end

defimpl Varar.CucumberExpressions.Expression,
  for: Varar.CucumberExpressions.CucumberExpression do
  alias Varar.CucumberExpressions.CucumberExpression

  def match(expression, text), do: CucumberExpression.match(expression, text)
  def regex(expression), do: CucumberExpression.regex(expression)
  def source(expression), do: expression.source
end

defimpl Varar.CucumberExpressions.Expression,
  for: Varar.CucumberExpressions.RegularExpression do
  alias Varar.CucumberExpressions.RegularExpression

  def match(expression, text), do: RegularExpression.match(expression, text)
  def regex(expression), do: RegularExpression.regex(expression)
  def source(expression), do: RegularExpression.source(expression)
end
