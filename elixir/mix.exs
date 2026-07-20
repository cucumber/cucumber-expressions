defmodule Cucumber.CucumberExpressions.MixProject do
  use Mix.Project

  @version "20.0.0"
  @source_url "https://github.com/oselvar/cucumber-expressions"

  def project do
    [
      app: :cucumber_cucumber_expressions,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "Cucumber Expressions",
      description:
        "Cucumber Expressions - a simpler alternative to Regular Expressions. " <>
          "Elixir port maintained by Oselvar.",
      package: package(),
      docs: docs(),
      # Testdata is a test-support helper, not library code.
      test_coverage: [
        summary: [threshold: 100],
        ignore_modules: [Cucumber.CucumberExpressions.Testdata]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:decimal, "~> 2.0 or ~> 3.0"},
      {:yaml_elixir, "~> 2.9", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Upstream" => "https://github.com/cucumber/cucumber-expressions"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
