import 'package:cucumber_expressions/src/generated_expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:test/test.dart';

ParameterType<Object?> type(String name) =>
    ParameterType<Object?>(name, '.*', name, (values) => values.first);

void main() {
  group('GeneratedExpression', () {
    test('renders placeholders and disambiguates repeated parameter names', () {
      final expression = createGeneratedExpression('I have {{0}} and {{1}}', [
        type('item'),
        type('item'),
      ]);
      expect(expression.source, 'I have {item} and {item}');
      expect(expression.parameterNames, ['item', 'item2']);
    });
  });
}
