[![test-go](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-go.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-go.yml)
[![test-java](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-java.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-java.yml)
[![test-javascript](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-javascript.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-javascript.yml)
[![test-python](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-python.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-python.yml)
[![test-ruby](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-ruby.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-ruby.yml)
[![test-dotnet](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-dotnet.yml/badge.svg)](https://github.com/cucumber/cucumber-expressions/actions/workflows/test-dotnet.yml)
[![test-elixir](https://github.com/oselvar/cucumber-expressions/actions/workflows/test-elixir.yml/badge.svg)](https://github.com/oselvar/cucumber-expressions/actions/workflows/test-elixir.yml)

# Cucumber Expressions

> **This fork** ([oselvar/cucumber-expressions](https://github.com/oselvar/cucumber-expressions))
> adds an [Elixir port](elixir/) maintained by [Oselvar](https://github.com/oselvar).

Cucumber Expressions is an alternative to [Regular Expressions](https://en.wikipedia.org/wiki/Regular_expression)
with a more intuitive syntax.

## Documentation

Full documentation is at <https://cucumber.io/docs/cucumber/cucumber-expressions> including syntax, usage examples, and an interactive playground.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md)

## Acknowledgements

The Cucumber Expression syntax is inspired by similar expression syntaxes in
other BDD tools, such as [Turnip](https://github.com/jnicklas/turnip),
[Behat](https://github.com/Behat/Behat) and
[Behave](https://github.com/behave/behave).

Big thanks to Jonas Nicklas, Konstantin Kudryashov and Jens Engel for
implementing those libraries.

The [Tiny-Compiler-Parser tutorial](https://blog.klipse.tech/javascript/2017/02/08/tiny-compiler-parser.html)
by [Yehonathan Sharvit](https://github.com/viebel) inspired the design of the
Cucumber expression parser.
