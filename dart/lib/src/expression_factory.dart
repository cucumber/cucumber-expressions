import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/expression.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';

/// Creates [Expression]s from either a [String] Cucumber Expression or a
/// [RegExp] regular expression.
class ExpressionFactory {
  /// Creates a factory backed by [_parameterTypeRegistry].
  ExpressionFactory(this._parameterTypeRegistry);

  final ParameterTypeRegistry _parameterTypeRegistry;

  /// Creates an [Expression] from [expression].
  ///
  /// [expression] must be a [String] or a [RegExp]; otherwise an
  /// [ArgumentError] is thrown.
  Expression createExpression(Object expression) {
    if (expression is RegExp) {
      return RegularExpression(expression, _parameterTypeRegistry);
    }
    if (expression is String) {
      return CucumberExpression(expression, _parameterTypeRegistry);
    }
    throw ArgumentError(
      'Expression must be a String or a RegExp, was ${expression.runtimeType}',
    );
  }
}
