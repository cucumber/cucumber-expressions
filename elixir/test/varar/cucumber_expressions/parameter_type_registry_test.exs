defmodule Varar.CucumberExpressions.ParameterTypeRegistryTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{ParameterType, ParameterTypeRegistry}

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
      |> ParameterTypeRegistry.add!(type("name", true))
      |> ParameterTypeRegistry.add!(type("person", false))

    assert {:error, error} = ParameterTypeRegistry.add(registry, type("place", true))

    assert Exception.message(error) ==
             "There can only be one preferential parameter type per regexp. " <>
               "The regexp /[A-Z]+\\w+/ is used for two: {name} and {place}"
  end

  test "looks up preferential parameter type by regexp" do
    registry =
      ParameterTypeRegistry.new()
      |> ParameterTypeRegistry.add!(type("name", false))
      |> ParameterTypeRegistry.add!(type("person", true))
      |> ParameterTypeRegistry.add!(type("place", false))

    looked_up =
      ParameterTypeRegistry.lookup_by_regexp(
        registry,
        @capitalised_word,
        "([A-Z]+\\w+) and ([A-Z]+\\w+)",
        "Lisa and Bob"
      )

    assert looked_up.name == "person"
  end
end
