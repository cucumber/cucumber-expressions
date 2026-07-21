defmodule Cucumber.CucumberExpressions.ParameterTypeTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.ParameterType

  test "does not allow flags on regexps" do
    assert {:error, error} = ParameterType.new(name: "case-insensitive", regexps: ~r/[a-z]+/i)
    assert Exception.message(error) == "ParameterType Regexps can't use flags"
  end

  test "accepts plain and unicode regexps" do
    assert {:ok, _} = ParameterType.new(name: "plain", regexps: ~r/[a-z]+/)
    assert {:ok, _} = ParameterType.new(name: "unicode", regexps: ~r/[a-z]+/u)
  end

  test "rejects a regexp source that does not compile" do
    assert {:error, error} = ParameterType.new(name: "bad", regexps: "([")

    assert Exception.message(error) ==
             "ParameterType Regexp /([/ is not a valid regular expression"
  end

  test "anonymous?/1 is true only for the empty name" do
    assert [name: "", regexps: ".*"] |> ParameterType.new!() |> ParameterType.anonymous?()
    refute [name: "int", regexps: "\\d+"] |> ParameterType.new!() |> ParameterType.anonymous?()
    refute [name: nil, regexps: ".*"] |> ParameterType.new!() |> ParameterType.anonymous?()
  end
end
