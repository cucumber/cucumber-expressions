import 'package:cucumber_expressions/cucumber_expressions.dart';
import 'package:test/test.dart';

void main() {
  test('creates and matches expressions through the public factory', () {
    final expression = ExpressionFactory(ParameterTypeRegistry())
        .createExpression('I have {int} cukes');

    final arguments = expression.match('I have 42 cukes');

    expect(arguments, isNotNull);
    expect(arguments![0].getValue(), equals(42));
  });

  test('creates regular expressions through the public factory', () {
    final expression =
        ExpressionFactory(ParameterTypeRegistry()).createExpression(
      RegExp(r'I have (\d+) cukes'),
    );

    final arguments = expression.match('I have 42 cukes');

    expect(arguments, isNotNull);
    expect(arguments![0].getValue(), equals(42));
  });
}
