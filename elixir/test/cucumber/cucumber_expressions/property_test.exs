defmodule Cucumber.CucumberExpressions.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Cucumber.CucumberExpressions.CucumberExpression
  alias Cucumber.CucumberExpressions.CucumberExpressionGenerator
  alias Cucumber.CucumberExpressions.CucumberExpressionParser
  alias Cucumber.CucumberExpressions.ParameterTypeRegistry

  # The shared testdata corpus covers the cases someone thought to write down.
  # These properties cover the ones nobody did — in particular the syntax
  # metacharacters, where unbalanced or escaped input is most likely to escape
  # the {:ok, _} | {:error, _} contract.

  # Weighted towards `{}`, `()`, `/` and `\`, because uniform random text almost
  # never produces them and they are where the parser actually branches.
  defp expression_source do
    fragment =
      StreamData.frequency([
        {5, StreamData.string(:alphanumeric, min_length: 1, max_length: 3)},
        {4,
         StreamData.member_of([
           "{",
           "}",
           "(",
           ")",
           "/",
           "\\",
           " ",
           "|",
           "^",
           "$",
           "*",
           "+",
           "?",
           "[",
           "]"
         ])},
        {2, StreamData.member_of(["{int}", "{word}", "{string}", "{float}", "{}", "(s)", "a/b"])}
      ])

    fragment
    |> StreamData.list_of(min_length: 1, max_length: 8)
    |> StreamData.map(&Enum.join/1)
  end

  # Step text shaped so the built-in parameter types actually fire: words,
  # spaces, integers, floats and quoted strings.
  defp step_text do
    [
      {4, StreamData.string(:alphanumeric, min_length: 1, max_length: 5)},
      {3, StreamData.constant(" ")},
      {2, StreamData.map(StreamData.integer(-999..999), &to_string/1)},
      {1, StreamData.member_of(["\"quoted\"", "3.14", "(", "{", "/"])}
    ]
    |> StreamData.frequency()
    |> StreamData.list_of(min_length: 1, max_length: 8)
    |> StreamData.map(&Enum.join/1)
  end

  property "compile/2 always returns a tagged tuple, never raises" do
    registry = ParameterTypeRegistry.new()

    check all(source <- expression_source(), max_runs: 500) do
      assert {tag, _} = CucumberExpression.compile(source, registry)
      assert tag in [:ok, :error]
    end
  end

  property "parse/1 always returns a tagged tuple, never raises" do
    check all(source <- expression_source(), max_runs: 500) do
      assert {tag, _} = CucumberExpressionParser.parse(source)
      assert tag in [:ok, :error]
    end
  end

  # The generator's whole purpose is suggesting an expression for a step that
  # did not match. A suggestion that fails to compile, or compiles but does not
  # match the text it was derived from, is useless.
  property "every generated expression compiles and matches the text it came from" do
    registry = ParameterTypeRegistry.new()

    check all(text <- step_text(), max_runs: 200) do
      for generated <- CucumberExpressionGenerator.generate_expressions(registry, text) do
        assert {:ok, expression} = CucumberExpression.compile(generated.source, registry),
               "generated #{inspect(generated.source)} for #{inspect(text)} does not compile"

        assert CucumberExpression.match(expression, text),
               "generated #{inspect(generated.source)} does not match #{inspect(text)}"
      end
    end
  end
end
