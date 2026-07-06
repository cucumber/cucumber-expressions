import 'cucumber_expression.dart';
import 'expression.dart';
import 'parameter_type_registry.dart';
import 'regular_expression.dart';

class ExpressionFactory {
  ExpressionFactory(this._parameterTypeRegistry);

  final ParameterTypeRegistry _parameterTypeRegistry;

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
