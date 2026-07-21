/// Cucumber Expressions for Dart.
///
/// An alternative to regular expressions with a more intuitive syntax. Full
/// syntax reference, usage examples, and an interactive playground are at
/// <https://cucumber.io/docs/cucumber/cucumber-expressions>.
///
/// Provides Dart types for Cucumber Expressions and regular expressions,
/// parameter type matching, and expression generation.
///
/// ```dart
/// import 'package:cucumber_expressions/cucumber_expressions.dart';
///
/// final expression = ExpressionFactory(
///   ParameterTypeRegistry(),
/// ).createExpression('I have {int} cukes');
///
/// final arguments = expression.match('I have 24 cukes');
/// print(arguments?.first.getValue()); // 24
/// ```
library;

export 'src/argument.dart' show Argument;
export 'src/cucumber_expression_generator.dart'
    show CucumberExpressionGenerator;
export 'src/errors.dart'
    show
        AmbiguousParameterTypeException,
        CucumberExpressionException,
        UndefinedParameterTypeException;
export 'src/expression.dart';
export 'src/expression_factory.dart';
export 'src/generated_expression.dart' show GeneratedExpression;
export 'src/group.dart' show Group;
export 'src/parameter_type.dart' show ParameterType, Transformer;
export 'src/parameter_type_registry.dart' show ParameterTypeRegistry;
