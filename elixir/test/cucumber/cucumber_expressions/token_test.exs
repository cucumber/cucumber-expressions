defmodule Cucumber.CucumberExpressions.TokenTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.Token

  test "type_string/1 returns the upstream name" do
    assert Token.type_string(:start_of_line) == "START_OF_LINE"
    assert Token.type_string(:begin_parameter) == "BEGIN_PARAMETER"
    assert Token.type_string(:text) == "TEXT"
  end

  test "escape_character?/1 recognises the backslash" do
    assert Token.escape_character?(?\\)
    refute Token.escape_character?(?a)
  end

  test "symbol/1 returns the literal character, or empty for types without one" do
    assert Token.symbol(:begin_optional) == "("
    assert Token.symbol(:end_optional) == ")"
    assert Token.symbol(:begin_parameter) == "{"
    assert Token.symbol(:end_parameter) == "}"
    assert Token.symbol(:alternation) == "/"
    assert Token.symbol(:text) == ""
    assert Token.symbol(:start_of_line) == ""
  end

  test "purpose/1 describes the construct a token belongs to" do
    assert Token.purpose(:begin_optional) == "optional text"
    assert Token.purpose(:end_optional) == "optional text"
    assert Token.purpose(:begin_parameter) == "a parameter"
    assert Token.purpose(:end_parameter) == "a parameter"
    assert Token.purpose(:alternation) == "alternation"
    assert Token.purpose(:text) == ""
    assert Token.purpose(:white_space) == ""
  end
end
