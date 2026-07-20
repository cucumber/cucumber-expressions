defmodule Cucumber.CucumberExpressions.NumberConversionTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.ParameterTypeRegistry, as: Registry

  describe "to_integer/1" do
    test "passes nil through, so a non-participating group stays nil" do
      assert Registry.to_integer(nil) == nil
    end

    test "parses signed integers" do
      assert Registry.to_integer("42") == 42
      assert Registry.to_integer("-42") == -42
    end
  end

  describe "to_float/1" do
    test "passes nil through, so a non-participating group stays nil" do
      assert Registry.to_float(nil) == nil
    end

    test "parses floats with an implicit leading zero" do
      assert Registry.to_float(".5") == 0.5
      assert Registry.to_float("-.5") == -0.5
      assert Registry.to_float("+.5") == 0.5
    end

    test "falls back to 0.0 for unparseable input" do
      assert Registry.to_float("abc") == 0.0
    end
  end

  describe "to_decimal/1" do
    test "passes nil through, so a non-participating group stays nil" do
      assert Registry.to_decimal(nil) == nil
    end

    test "parses an explicit sign" do
      assert decimal_string("-1.5") == "-1.5"
      assert decimal_string("+1.5") == "1.5"
      assert decimal_string("1.5") == "1.5"
    end

    test "parses scientific notation in either case" do
      assert decimal_string("-1.5e3") == "-1500"
      assert decimal_string("+2E2") == "200"
      assert decimal_string("1.5e-3") == "0.0015"
    end

    test "parses integers with no fractional part" do
      assert decimal_string("42") == "42"
    end

    test "keeps precision beyond what Decimal.new/1 would parse" do
      digits = String.duplicate("9", 100)
      assert decimal_string(digits) == digits
    end
  end

  defp decimal_string(string), do: string |> Registry.to_decimal() |> Decimal.to_string(:normal)
end
