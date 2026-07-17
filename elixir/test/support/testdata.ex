defmodule Varar.CucumberExpressions.Testdata do
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
end
