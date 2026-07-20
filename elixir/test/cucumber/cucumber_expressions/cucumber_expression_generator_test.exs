defmodule Cucumber.CucumberExpressions.CucumberExpressionGeneratorTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{
    CucumberExpression,
    GeneratedExpression,
    CucumberExpressionGenerator,
    ParameterType,
    ParameterTypeRegistry
  }

  defp assert_expression(registry, expected_expression, expected_argument_names, text) do
    generated = hd(CucumberExpressionGenerator.generate_expressions(registry, text))
    assert GeneratedExpression.parameter_names(generated) == expected_argument_names
    assert generated.source == expected_expression

    expression = CucumberExpression.compile!(generated.source, registry)
    match = CucumberExpression.match(expression, text)
    refute match == nil, "Expected text '#{text}' to match generated expression"
    assert length(match) == length(expected_argument_names)
  end

  defp define_parameter_type!(registry, options),
    do: ParameterTypeRegistry.define_parameter_type!(registry, ParameterType.new!(options))

  setup do
    {:ok, registry: ParameterTypeRegistry.new()}
  end

  test "documents expression generation", %{registry: registry} do
    undefined_step_text = "I have 2 cucumbers and 1.5 tomato"

    generated =
      hd(CucumberExpressionGenerator.generate_expressions(registry, undefined_step_text))

    assert generated.source == "I have {int} cucumbers and {float} tomato"
    assert Enum.at(generated.parameter_types, 1).type == :float
  end

  test "generates expression for no args", %{registry: registry} do
    assert_expression(registry, "hello", [], "hello")
  end

  test "generates expression with escaped left parenthesis", %{registry: registry} do
    assert_expression(registry, "\\(iii)", [], "(iii)")
  end

  test "generates expression with escaped left curly brace", %{registry: registry} do
    assert_expression(registry, "\\{iii}", [], "{iii}")
  end

  test "generates expression with escaped slashes", %{registry: registry} do
    assert_expression(
      registry,
      "The {int}\\/{int}\\/{int} hey",
      ["int", "int2", "int3"],
      "The 1814/05/17 hey"
    )
  end

  test "generates expression for int float arg", %{registry: registry} do
    assert_expression(
      registry,
      "I have {int} cukes and {float} euro",
      ["int", "float"],
      "I have 2 cukes and 1.5 euro"
    )
  end

  test "generates expression for strings", %{registry: registry} do
    assert_expression(
      registry,
      "I like {string} and {string}",
      ["string", "string2"],
      "I like \"bangers\" and 'mash'"
    )
  end

  test "generates expression with % sign", %{registry: registry} do
    assert_expression(registry, "I am {int}% foobar", ["int"], "I am 20% foobar")
  end

  test "generates expression for just int", %{registry: registry} do
    assert_expression(registry, "{int}", ["int"], "99999")
  end

  test "numbers only second argument when builtin type is not reserved keyword", %{
    registry: registry
  } do
    assert_expression(
      registry,
      "I have {int} cukes and {int} euro",
      ["int", "int2"],
      "I have 2 cukes and 5 euro"
    )
  end

  test "numbers only second argument when type is not reserved keyword", %{registry: registry} do
    registry =
      define_parameter_type!(registry,
        name: "currency",
        regexps: "[A-Z]{3}",
        type: :currency,
        prefer_for_regexp_match: true
      )

    assert_expression(
      registry,
      "I have a {currency} account and a {currency} account",
      ["currency", "currency2"],
      "I have a EUR account and a GBP account"
    )
  end

  test "exposes parameters in a generated expression", %{registry: registry} do
    generated =
      hd(
        CucumberExpressionGenerator.generate_expressions(registry, "I have 2 cukes and 1.5 euro")
      )

    assert Enum.map(generated.parameter_types, & &1.type) == [:integer, :float]
  end

  test "matches parameter types with optional capture groups", %{registry: registry} do
    registry =
      registry
      |> define_parameter_type!(name: "optional-flight", regexps: ~r/(1st flight)?/)
      |> define_parameter_type!(name: "optional-hotel", regexps: ~r/(1 hotel)?/)

    generated =
      hd(
        CucumberExpressionGenerator.generate_expressions(
          registry,
          "I reach Stage 4: 1st flight -1 hotel"
        )
      )

    # While you would expect this to be `I reach Stage {int}: {optional-flight} -{optional-hotel}`
    # the `-1` causes {int} to match just before {optional-hotel}.
    assert generated.source == "I reach Stage {int}: {optional-flight} {int} hotel"
  end

  test "generates at most 256 expressions", %{registry: registry} do
    registry =
      Enum.reduce(0..3, registry, fn i, registry ->
        define_parameter_type!(registry, name: "my-type-#{i}", regexps: ~r/([a-z] )*?[a-z]/)
      end)

    # This would otherwise generate 4^11=4194304 expressions.
    expressions =
      CucumberExpressionGenerator.generate_expressions(registry, "a s i m p l e s t e p")

    assert length(expressions) == 256
  end

  test "prefers expression with longest non empty match", %{registry: registry} do
    registry =
      registry
      |> define_parameter_type!(name: "zero-or-more", regexps: ~r/[a-z]*/)
      |> define_parameter_type!(name: "exactly-one", regexps: ~r/[a-z]/)

    expressions = CucumberExpressionGenerator.generate_expressions(registry, "a simple step")
    assert length(expressions) == 2
    assert Enum.at(expressions, 0).source == "{exactly-one} {zero-or-more} {zero-or-more}"
    assert Enum.at(expressions, 1).source == "{zero-or-more} {zero-or-more} {zero-or-more}"
  end

  describe "word boundaries" do
    setup %{registry: registry} do
      {:ok, registry: define_parameter_type!(registry, name: "direction", regexps: ~r/(up|down)/)}
    end

    test "does not suggest a parameter at the beginning of a word", %{registry: registry} do
      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "When I download a picture"
               )
             ).source ==
               "When I download a picture"
    end

    test "does not suggest a parameter inside a word", %{registry: registry} do
      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "When I watch the muppet show"
               )
             ).source ==
               "When I watch the muppet show"
    end

    test "does not suggest a parameter at the end of a word", %{registry: registry} do
      assert hd(
               CucumberExpressionGenerator.generate_expressions(registry, "When I create a group")
             ).source ==
               "When I create a group"
    end

    test "suggests a parameter for a full word", %{registry: registry} do
      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "When I go down the road"
               )
             ).source ==
               "When I go {direction} the road"

      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "When I walk up the hill"
               )
             ).source ==
               "When I walk {direction} the hill"

      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "up the hill, the road goes down"
               )
             ).source ==
               "{direction} the hill, the road goes {direction}"
    end

    test "suggests a parameter wrapped around punctuation characters", %{registry: registry} do
      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "When direction is:down"
               )
             ).source ==
               "When direction is:{direction}"

      assert hd(
               CucumberExpressionGenerator.generate_expressions(
                 registry,
                 "Then direction is down."
               )
             ).source ==
               "Then direction is {direction}."
    end
  end
end
