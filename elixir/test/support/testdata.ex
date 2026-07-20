defmodule Cucumber.CucumberExpressions.Testdata do
  @moduledoc """
  Loads the language-neutral conformance fixtures from the shared `testdata/`
  directory at the repository root.

  Each suite is a directory of YAML files; every file is one test case. Test
  modules call `load/1` at compile time and generate one ExUnit test per file,
  following the convention established by the other language ports.
  """

  @testdata_dir Path.expand("../../../testdata", __DIR__)

  @doc "Absolute path to the shared testdata directory."
  def dir, do: @testdata_dir

  @doc """
  Loads all fixtures for a suite, e.g. `"cucumber-expression/tokenizer"`.

  Returns `[{name, fixture}]` sorted by file name, where `name` is the file
  base name and `fixture` the parsed YAML document as a map.
  """
  def load(suite) do
    [@testdata_dir, suite, "*.yaml"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(fn path ->
      {Path.basename(path, ".yaml"), YamlElixir.read_from_file!(path)}
    end)
  end

  @doc """
  Formats a transformed argument value the way the matching fixtures encode
  it, mirroring the Ruby spec: decimals and integers wider than 64 bits are
  encoded as strings in the YAML.
  """
  def format_value(%Decimal{} = decimal), do: Decimal.to_string(decimal, :normal)

  def format_value(value) when is_integer(value) do
    if bit_length(value) > 64, do: Integer.to_string(value), else: value
  end

  def format_value(value), do: value

  defp bit_length(value) when value < 0, do: bit_length(-value - 1)
  defp bit_length(0), do: 0
  defp bit_length(value), do: length(Integer.digits(value, 2))
end
