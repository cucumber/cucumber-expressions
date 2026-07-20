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
    assert Token.symbol_of(:begin_optional) == "("
    assert Token.symbol_of(:end_optional) == ")"
    assert Token.symbol_of(:begin_parameter) == "{"
    assert Token.symbol_of(:end_parameter) == "}"
    assert Token.symbol_of(:alternation) == "/"
    assert Token.symbol_of(:text) == ""
    assert Token.symbol_of(:start_of_line) == ""
  end

  test "purpose/1 describes the construct a token belongs to" do
    assert Token.purpose_of(:begin_optional) == "optional text"
    assert Token.purpose_of(:end_optional) == "optional text"
    assert Token.purpose_of(:begin_parameter) == "a parameter"
    assert Token.purpose_of(:end_parameter) == "a parameter"
    assert Token.purpose_of(:alternation) == "alternation"
    assert Token.purpose_of(:text) == ""
    assert Token.purpose_of(:white_space) == ""
  end
end
