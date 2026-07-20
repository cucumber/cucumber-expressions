defmodule Cucumber.CucumberExpressions.CustomParameterTypeTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.Argument
  alias Cucumber.CucumberExpressions.CucumberExpression
  alias Cucumber.CucumberExpressions.ParameterType
  alias Cucumber.CucumberExpressions.ParameterTypeRegistry
  alias Cucumber.CucumberExpressions.RegularExpression

  defp registry_with_color do
    ParameterTypeRegistry.define_parameter_type!(
      ParameterTypeRegistry.new(),
      ParameterType.new!(
        name: "color",
        regexps: ~r/red|blue|yellow/,
        type: :color,
        transformer: fn s -> {:color, s} end
      )
    )
  end

  defp first_value(args), do: args |> hd() |> Argument.value()

  test "returns an error for an illegal character in a parameter name" do
    assert {:error, error} = ParameterType.new(name: "[string]", regexps: ".*")

    assert Exception.message(error) ==
             "Illegal character in parameter name {[string]}. " <>
               "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'"
  end

  test "matches parameters with custom parameter type" do
    expression = CucumberExpression.compile!("I have a {color} ball", registry_with_color())
    args = CucumberExpression.match(expression, "I have a red ball")
    assert first_value(args) == {:color, "red"}
  end

  test "matches parameters with multiple capture groups" do
    registry =
      ParameterTypeRegistry.define_parameter_type!(
        registry_with_color(),
        ParameterType.new!(
          name: "coordinate",
          regexps: ~r/(\d+),\s*(\d+),\s*(\d+)/,
          type: :coordinate,
          transformer: fn x, y, z ->
            {:coordinate, String.to_integer(x), String.to_integer(y), String.to_integer(z)}
          end
        )
      )

    expression =
      CucumberExpression.compile!(
        "A {int} thick line from {coordinate} to {coordinate}",
        registry
      )

    args = CucumberExpression.match(expression, "A 5 thick line from 10,20,30 to 40,50,60")

    assert Enum.map(args, &Argument.value/1) == [
             5,
             {:coordinate, 10, 20, 30},
             {:coordinate, 40, 50, 60}
           ]
  end

  test "matches parameters with custom parameter type using multiple regexps" do
    registry =
      ParameterTypeRegistry.define_parameter_type!(
        ParameterTypeRegistry.new(),
        ParameterType.new!(
          name: "color",
          regexps: [~r/red|blue|yellow/, ~r/(?:dark|light) (?:red|blue|yellow)/],
          type: :color,
          transformer: fn s -> {:color, s} end
        )
      )

    expression = CucumberExpression.compile!("I have a {color} ball", registry)
    args = CucumberExpression.match(expression, "I have a dark red ball")
    assert first_value(args) == {:color, "dark red"}
  end

  test "defers transformation until queried from argument" do
    registry =
      ParameterTypeRegistry.define_parameter_type!(
        registry_with_color(),
        ParameterType.new!(
          name: "throwing",
          regexps: "bad",
          transformer: fn s -> raise "Can't transform [#{s}]" end
        )
      )

    expression = CucumberExpression.compile!("I have a {throwing} parameter", registry)
    args = CucumberExpression.match(expression, "I have a bad parameter")

    assert_raise RuntimeError, "Can't transform [bad]", fn -> first_value(args) end
  end

  test "conflicting parameter type is detected for type name" do
    assert {:error, error} =
             ParameterTypeRegistry.define_parameter_type(
               registry_with_color(),
               ParameterType.new!(name: "color", regexps: ".*")
             )

    assert Exception.message(error) == "There is already a parameter with name color"
  end

  test "conflicting parameter type is not detected for regexp" do
    registry =
      ParameterTypeRegistry.define_parameter_type!(
        registry_with_color(),
        ParameterType.new!(
          name: "css-color",
          regexps: ~r/red|blue|yellow/,
          type: :css_color,
          transformer: fn s -> {:css_color, s} end
        )
      )

    css_color = CucumberExpression.compile!("I have a {css-color} ball", registry)

    assert first_value(CucumberExpression.match(css_color, "I have a blue ball")) ==
             {:css_color, "blue"}

    color = CucumberExpression.compile!("I have a {color} ball", registry)
    assert first_value(CucumberExpression.match(color, "I have a blue ball")) == {:color, "blue"}
  end

  test "RegularExpression matches arguments with custom parameter types without a name" do
    registry =
      ParameterTypeRegistry.define_parameter_type!(
        ParameterTypeRegistry.new(),
        ParameterType.new!(
          name: nil,
          regexps: ~r/red|blue|yellow/,
          type: :color,
          transformer: fn s -> {:color, s} end
        )
      )

    expression = RegularExpression.compile!(~r/I have a (red|blue|yellow) ball/, registry)
    args = RegularExpression.match(expression, "I have a red ball")
    assert first_value(args) == {:color, "red"}
  end
end
