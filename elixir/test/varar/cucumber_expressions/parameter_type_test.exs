defmodule Varar.CucumberExpressions.ParameterTypeTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.ParameterType

  test "does not allow flags on regexps" do
    assert {:error, error} = ParameterType.new(name: "case-insensitive", regexps: ~r/[a-z]+/i)
    assert Exception.message(error) == "ParameterType Regexps can't use flags"
  end

  test "accepts plain and unicode regexps" do
    assert {:ok, _} = ParameterType.new(name: "plain", regexps: ~r/[a-z]+/)
    assert {:ok, _} = ParameterType.new(name: "unicode", regexps: ~r/[a-z]+/u)
  end
end
