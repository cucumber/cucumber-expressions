# Cucumber Expressions for Elixir

[The main docs are here](https://github.com/cucumber/cucumber-expressions#readme).

This is the Elixir port of Cucumber Expressions, maintained by
[Oselvar](https://github.com/oselvar) in a fork of the upstream
[cucumber/cucumber-expressions](https://github.com/cucumber/cucumber-expressions)
repository. It is verified against the same language-neutral `testdata`
conformance corpus as the other ports.

## Installation

Add `varar_cucumber_expressions` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:varar_cucumber_expressions, "~> 20.0"}
  ]
end
```

## Usage

```elixir
alias Varar.CucumberExpressions, as: CE

registry = CE.ParameterTypeRegistry.new()
{:ok, expression} = CE.compile("I have {int} cuke(s)", registry)

case CE.Expression.match(expression, "I have 7 cukes") do
  nil -> :no_match
  args -> Enum.map(args, &CE.Argument.value/1) # => [7]
end
```

(The API is under construction — see the milestone plan in the repository.)

## Development

```bash
make          # deps + format check + tests
mix test      # just the tests
```

The test suite generates one ExUnit test per YAML file in the repository-root
`../testdata` directory, so the port stays conformant with upstream.
