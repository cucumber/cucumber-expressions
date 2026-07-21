defmodule Cucumber.CucumberExpressionsDocTest do
  use ExUnit.Case, async: true

  # Keeps the usage example in the moduledoc (and by extension the README)
  # executable, so it cannot drift from the API.
  doctest Cucumber.CucumberExpressions
end
