import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:test/test.dart';

List<Object?>? match(String expression, String text) => CucumberExpression(
      expression,
      ParameterTypeRegistry(),
    ).match(text)?.map((argument) => argument.getValue()).toList();

void main() {
  group('CucumberExpression', () {
    test('matches the complete text', () {
      expect(match('{int}', '42'), equals([42]));
      expect(match('{int}', '42 cucumbers'), isNull);
    });

    test('matches exponent floats and rejects grouped numbers', () {
      expect(match('{float}', '-.1E+2'), equals([-10.0]));
      expect(match('{float}', '1,000.1'), isNull);
    });

    test('rejects incomplete floats', () {
      for (final text in ['+', '-', '.', '1.', '1E', '1E+']) {
        expect(match('{float}', text), isNull);
      }
    });

    test('exposes its source', () {
      const source = 'I have {int} cuke(s)';
      expect(
        CucumberExpression(source, ParameterTypeRegistry()).source,
        source,
      );
    });

    test('passes unmatched nested capture groups to transformers', () {
      final registry = ParameterTypeRegistry()
        ..defineParameterType(
          ParameterType<List<String?>>(
            'textOrNumber',
            RegExp('([A-Z]+)?(?: )?([0-9]+)?'),
            'List<String?>',
            (values) => values,
            useForSnippets: false,
            preferForRegexpMatch: true,
          ),
        );
      final expression = CucumberExpression('{textOrNumber}', registry);

      expect(expression.match('TLA')!.single.getValue(), ['TLA', null]);
      expect(expression.match('123')!.single.getValue(), [null, '123']);
    });

    test('defers transformer failures until the argument is read', () {
      final registry = ParameterTypeRegistry()
        ..defineParameterType(
          ParameterType<String?>(
            'throwing',
            'bad',
            'String',
            (values) => throw StateError('Cannot transform ${values.first}'),
            useForSnippets: false,
            preferForRegexpMatch: true,
          ),
        );
      final arguments =
          CucumberExpression('{throwing}', registry).match('bad')!;

      expect(() => arguments.single.getValue(), throwsStateError);
    });
  });
}
