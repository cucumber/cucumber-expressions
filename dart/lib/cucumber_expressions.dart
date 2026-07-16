/// Cucumber Expressions for Dart.
///
/// An alternative to regular expressions with a more intuitive syntax. Full
/// syntax reference, usage examples, and an interactive playground are at
/// <https://cucumber.io/docs/cucumber/cucumber-expressions>.
///
/// Provides Dart types for Cucumber Expressions and regular expressions,
/// parameter type matching, and expression generation.
library;

export 'src/argument.dart';
export 'src/cucumber_expression.dart';
export 'src/cucumber_expression_generator.dart';
export 'src/errors.dart'
    show
        AmbiguousParameterTypeException,
        CucumberExpressionException,
        UndefinedParameterTypeException;
export 'src/expression.dart' show Expression;
export 'src/expression_factory.dart';
export 'src/generated_expression.dart';
export 'src/group.dart';
export 'src/parameter_type.dart';
export 'src/parameter_type_registry.dart';
export 'src/regular_expression.dart';
