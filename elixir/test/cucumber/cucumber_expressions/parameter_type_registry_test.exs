defmodule Cucumber.CucumberExpressions.ParameterTypeRegistryTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{ParameterType, ParameterTypeRegistry}

  @capitalised_word "[A-Z]+\\w+"

  defp type(name, prefer) do
    ParameterType.new!(
      name: name,
      regexps: @capitalised_word,
      type: :string,
      prefer_for_regexp_match: prefer
    )
  end

  test "does not allow more than one preferential parameter type per regexp" do
    registry =
      ParameterTypeRegistry.new()
      |> ParameterTypeRegistry.define_parameter_type!(type("name", true))
      |> ParameterTypeRegistry.define_parameter_type!(type("person", false))

    assert {:error, error} =
             ParameterTypeRegistry.define_parameter_type(registry, type("place", true))

    assert Exception.message(error) ==
             "There can only be one preferential parameter type per regexp. " <>
               "The regexp /[A-Z]+\\w+/ is used for two: {name} and {place}"
  end

  test "looks up preferential parameter type by regexp" do
    registry =
      ParameterTypeRegistry.new()
      |> ParameterTypeRegistry.define_parameter_type!(type("name", false))
      |> ParameterTypeRegistry.define_parameter_type!(type("person", true))
      |> ParameterTypeRegistry.define_parameter_type!(type("place", false))

    looked_up =
      ParameterTypeRegistry.lookup_by_regexp(
        registry,
        @capitalised_word,
        "([A-Z]+\\w+) and ([A-Z]+\\w+)",
        "Lisa and Bob"
      )

    assert looked_up.name == "person"
  end

  test "raises ambiguous exception when no parameter types are preferential" do
    registry =
      ParameterTypeRegistry.new()
      |> ParameterTypeRegistry.define_parameter_type!(type("name", false))
      |> ParameterTypeRegistry.define_parameter_type!(type("person", false))
      |> ParameterTypeRegistry.define_parameter_type!(type("place", false))

    error =
      assert_raise Cucumber.CucumberExpressions.AmbiguousParameterTypeError, fn ->
        ParameterTypeRegistry.lookup_by_regexp(
          registry,
          @capitalised_word,
          "([A-Z]+\\w+) and ([A-Z]+\\w+)",
          "Lisa and Bob"
        )
      end

    assert Exception.message(error) ==
             "Your Regular Expression /([A-Z]+\\w+) and ([A-Z]+\\w+)/\n" <>
               "matches multiple parameter types with regexp /[A-Z]+\\w+/:\n" <>
               "   {name}\n   {person}\n   {place}\n" <>
               "\n" <>
               "I couldn't decide which one to use. You have two options:\n" <>
               "\n" <>
               "1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:\n" <>
               "   {name} and {name}\n" <>
               "   {name} and {person}\n" <>
               "   {name} and {place}\n" <>
               "   {person} and {name}\n" <>
               "   {person} and {person}\n" <>
               "   {person} and {place}\n" <>
               "   {place} and {name}\n" <>
               "   {place} and {person}\n" <>
               "   {place} and {place}\n" <>
               "\n" <>
               "2) Make one of the parameter types preferential and continue to use a Regular Expression.\n" <>
               "\n"
  end
end
