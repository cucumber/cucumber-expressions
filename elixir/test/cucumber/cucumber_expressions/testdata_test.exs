defmodule Cucumber.CucumberExpressions.TestdataTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.Testdata

  @suites [
    "cucumber-expression/tokenizer",
    "cucumber-expression/parser",
    "cucumber-expression/transformation",
    "cucumber-expression/matching",
    "regular-expression/matching"
  ]

  for suite <- @suites do
    test "finds and parses fixtures in #{suite}" do
      fixtures = Testdata.load(unquote(suite))
      assert fixtures != [], "no fixtures found — is ../testdata missing?"

      for {name, fixture} <- fixtures do
        assert Map.has_key?(fixture, "expression"), "#{name} has no 'expression' key"
      end
    end
  end
end
