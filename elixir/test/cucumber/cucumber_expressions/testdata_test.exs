defmodule Cucumber.CucumberExpressions.TestdataTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.Testdata

  # The suites this port executes. Each is driven by one conformance module,
  # which generates one ExUnit test per fixture file:
  #
  #   cucumber-expression/tokenizer      -> CucumberExpressionTokenizerTest
  #   cucumber-expression/parser         -> CucumberExpressionParserTest
  #   cucumber-expression/transformation -> CucumberExpressionTransformationTest
  #   cucumber-expression/matching       -> CucumberExpressionMatchingTest
  #   regular-expression/matching        -> RegularExpressionMatchingTest
  #
  # Those modules build their tests with a compile-time `for` comprehension, so
  # a suite that resolved to zero fixtures would generate zero tests and pass
  # silently. The assertions below are what make that impossible.
  @executed_suites [
    "cucumber-expression/matching",
    "cucumber-expression/parser",
    "cucumber-expression/tokenizer",
    "cucumber-expression/transformation",
    "regular-expression/matching"
  ]

  test "every suite in the shared corpus is executed" do
    assert Testdata.suites() == Enum.sort(@executed_suites), """
    The shared testdata corpus and the suites this port executes have diverged.

    In the corpus but not executed: #{inspect(Testdata.suites() -- @executed_suites)}
    Executed but not in the corpus: #{inspect(@executed_suites -- Testdata.suites())}

    A new upstream suite must either get a conformance module here, or be added
    to @executed_suites with a note explaining why it is out of scope.
    """
  end

  test "every fixture in the shared corpus is executed" do
    per_suite = Map.new(@executed_suites, &{&1, length(Testdata.load(&1))})
    executed = per_suite |> Map.values() |> Enum.sum()
    total = Testdata.fixture_count()

    assert executed > 0, "no fixtures found — is ../testdata missing?"

    assert executed == total, """
    #{executed} of #{total} shared fixtures are executed.

    Per suite: #{inspect(per_suite, pretty: true)}
    """
  end

  for suite <- @executed_suites do
    test "fixtures in #{suite} all carry an expression" do
      for {name, fixture} <- Testdata.load(unquote(suite)) do
        assert Map.has_key?(fixture, "expression"), "#{name} has no 'expression' key"
      end
    end
  end
end
