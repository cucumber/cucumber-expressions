import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/expression_factory.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionFactory', () {
    late ExpressionFactory expressionFactory;

    setUp(() {
      expressionFactory = ExpressionFactory(ParameterTypeRegistry());
    });

    test('creates a RegularExpression', () {
      expect(
        expressionFactory.createExpression(RegExp('x')),
        isA<RegularExpression>(),
      );
    });

    test('creates a CucumberExpression', () {
      expect(
        expressionFactory.createExpression('x'),
        isA<CucumberExpression>(),
      );
    });
  });
}
