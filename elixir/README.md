# Cucumber Expressions for Elixir

[The main docs are here](https://github.com/cucumber/cucumber-expressions#readme).

This is the Elixir port of Cucumber Expressions, maintained by
[Oselvar](https://github.com/oselvar) in a fork of the upstream
[cucumber/cucumber-expressions](https://github.com/cucumber/cucumber-expressions)
repository. It is verified against the same language-neutral `testdata`
conformance corpus as the other ports.

## Installation

Add `cucumber_cucumber_expressions` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:cucumber_cucumber_expressions, "~> 20.0"}
  ]
end
```

## Usage

```elixir
alias Cucumber.CucumberExpressions, as: CE

registry = CE.ParameterTypeRegistry.new()

{:ok, expression} = CE.compile("I have {int} cuke(s)", registry)

case CE.Expression.match(expression, "I have 7 cukes") do
  nil -> :no_match
  args -> Enum.map(args, &CE.Argument.value/1) # => [7]
end
```

`CE.compile/2` (and `CE.compile!/2`) accepts a string (compiled as a Cucumber
Expression) or a `Regex` (compiled as a Regular Expression whose capture
groups are transformed by matching parameter types) — the same dispatch
Cucumber applies to step definition patterns. Both results implement the
`CE.Expression` protocol.

### Custom parameter types

The registry is an immutable value — `add/2` returns a new registry that you
thread through your code:

```elixir
{:ok, registry} =
  CE.ParameterTypeRegistry.add(
    registry,
    CE.ParameterType.new!(
      name: "color",
      regexps: ~r/red|blue|yellow/,
      type: :color,
      transformer: &String.to_atom/1
    )
  )
```

### Notes on types

- `{int}` and `{biginteger}` produce Elixir's arbitrary-precision integers.
- `{float}` and `{double}` produce floats.
- `{bigdecimal}` produces a [`Decimal`](https://hex.pm/packages/decimal)
  struct with exact, unlimited precision.

## Development

```bash
make          # deps + format check + credo + dialyzer + tests with coverage
mix test      # just the tests
mix docs      # generate ExDoc documentation
```

The test suite generates one ExUnit test per YAML file in the repository-root
`../testdata` directory, so the port stays conformant with upstream:
tokenizer, parser, transformation, and both matching suites (cucumber
expressions and regular expressions). Behaviour without shared testdata
(TreeRegexp, custom parameter types, registry conflicts, the expression
generator) is covered by unit tests hand-ported from the Ruby implementation.
