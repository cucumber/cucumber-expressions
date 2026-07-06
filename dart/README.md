# Cucumber Expressions for Dart

[Cucumber Expressions](https://github.com/cucumber/cucumber-expressions) is an
alternative to [Regular Expressions](https://en.wikipedia.org/wiki/Regular_expression)
with a more intuitive syntax. Full syntax reference, usage examples, and an interactive
playground are at <https://cucumber.io/docs/cucumber/cucumber-expressions>.

This package provides Dart types for Cucumber Expressions and regular expressions,
parameter type matching, and expression generation.

## Requirements

* Dart SDK `^3.5.0`

## Installation

From the Git repository (monorepo subdirectory):

```yaml
dependencies:
  cucumber_expressions:
    git:
      url: https://github.com/cucumber/cucumber-expressions.git
      path: dart
```

When published to [pub.dev](https://pub.dev/packages/cucumber_expressions), add:

```yaml
dependencies:
  cucumber_expressions: ^<published-version>
```

Import the public API from the package root:

```dart
import 'package:cucumber_expressions/cucumber_expressions.dart';
```

Do not import from `package:cucumber_expressions/src/...`; files under `lib/src/` are
implementation details and may change without notice.

## Matching

Create a `ParameterTypeRegistry`, build a `CucumberExpression`, then call `match`.
`match` returns `null` when the text does not match, or a list of `Argument`s. Call
`getValue()` on each argument to run its parameter type transformer.

```dart
import 'package:cucumber_expressions/cucumber_expressions.dart';

final registry = ParameterTypeRegistry();
final expression = CucumberExpression('I have {int} cukes', registry);

final args = expression.match('I have 42 cukes');
if (args != null) {
  final count = args[0].getValue() as int; // 42
}
```

`int`, `float`, `word`, `string`, and the anonymous `{}` are built in.

## Custom parameter types

Register a `ParameterType` before building the expression. The transformer receives the
captured group values and returns the parameter value.

```dart
import 'package:cucumber_expressions/cucumber_expressions.dart';

class Color {
  Color(this.name);
  final String name;
}

final registry = ParameterTypeRegistry();
registry.defineParameterType(
  ParameterType<Color>(
    'color',
    RegExp('red|blue|yellow'),
    'Color',
    (groupValues) => Color(groupValues.first!),
  ),
);

final expression = CucumberExpression('I have a {color} ball', registry);
final color = expression.match('I have a red ball')?[0].getValue() as Color?;
```

`getValue()` runs the transformer lazily. It throws when called, not at match time.

## Regular expressions

`RegularExpression` matches against a `RegExp` and produces the same `Argument` list.
Use `ExpressionFactory` to build a `CucumberExpression` or `RegularExpression` from a
`String` or `RegExp`.

```dart
import 'package:cucumber_expressions/cucumber_expressions.dart';

final registry = ParameterTypeRegistry();
final expression = ExpressionFactory(registry)
    .createExpression(RegExp(r'I have (\d+) cukes'));

final args = expression.match('I have 42 cukes');
```

`createExpression` throws `ArgumentError` for any type other than `String` or `RegExp`.

## Errors

Parsing and matching failures throw `CucumberExpressionException` subclasses:
`UndefinedParameterTypeException` and `AmbiguousParameterTypeException`.

See the unit tests under [test/](test/) for more examples.

## Development

From the `dart/` directory:

```sh
dart pub get
dart format .
dart analyze
dart test
dart pub publish --dry-run
```

For general information about Cucumber Expressions and the other language
implementations, see the repository root [README](https://github.com/cucumber/cucumber-expressions/blob/main/README.md).
