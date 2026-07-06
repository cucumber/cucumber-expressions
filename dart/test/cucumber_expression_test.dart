import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'test_data_dir.dart';

List<Object?>? _match(String expression, String text) {
  final cucumberExpression =
      CucumberExpression(expression, ParameterTypeRegistry());
  final args = cucumberExpression.match(text);
  return args?.map((a) => a.getValue()).toList();
}

/// Normalises an actual matched value so it can be compared to the value that
/// `package:yaml` produced from the expectation file. The shared test data
/// compares values without type information, so BigInt is compared as its
/// decimal string and numbers are compared structurally.
Object? normalize(Object? value) {
  if (value == null) return null;
  if (value is BigInt) return value.toString();
  if (value is num) return value;
  if (value is String) return value;
  if (value is List) return value.map(normalize).toList();
  return value.toString();
}

Object? normalizeExpected(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return value;
  if (value is YamlList) return value.map(normalizeExpected).toList();
  if (value is List) return value.map(normalizeExpected).toList();
  return value.toString();
}

void main() {
  group('CucumberExpression', () {
    for (final file
        in yamlFilesIn('$testDataDir/cucumber-expression/matching')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('matches ${file.path}', () {
        final expression = expectation['expression'] as String;
        final text = expectation['text'] as String?;
        if (expectation.containsKey('expected_args')) {
          final registry = ParameterTypeRegistry();
          final cucumberExpression = CucumberExpression(expression, registry);
          final matches = cucumberExpression.match(text ?? '');
          final actual = matches?.map((a) => normalize(a.getValue())).toList();
          final expected = normalizeExpected(expectation['expected_args']);
          expect(actual, equals(expected));
        } else if (expectation['exception'] != null) {
          expect(
            () {
              final registry = ParameterTypeRegistry();
              final cucumberExpression =
                  CucumberExpression(expression, registry);
              cucumberExpression.match(text ?? '');
            },
            throwsA(
              isA<CucumberExpressionException>().having(
                (e) => e.message,
                'message',
                equals(expectation['exception']),
              ),
            ),
          );
        } else {
          fail('Expectation must have expected_args or exception');
        }
      });
    }

    test('matches float', () {
      expect(_match('{float}', ''), isNull);
      expect(_match('{float}', '.'), isNull);
      expect(_match('{float}', ','), isNull);
      expect(_match('{float}', '-'), isNull);
      expect(_match('{float}', 'E'), isNull);
      expect(_match('{float}', '1,'), isNull);
      expect(_match('{float}', ',1'), isNull);
      expect(_match('{float}', '1.'), isNull);

      expect(_match('{float}', '1'), equals([1.0]));
      expect(_match('{float}', '-1'), equals([-1.0]));
      expect(_match('{float}', '1.1'), equals([1.1]));
      expect(_match('{float}', '1,000'), isNull);
      expect(_match('{float}', '1,000,0'), isNull);
      expect(_match('{float}', '1,000.1'), isNull);
      expect(_match('{float}', '1,000,10'), isNull);
      expect(_match('{float}', '1,0.1'), isNull);
      expect(_match('{float}', '1,000,000.1'), isNull);
      expect(_match('{float}', '-1.1'), equals([-1.1]));

      expect(_match('{float}', '.1'), equals([0.1]));
      expect(_match('{float}', '-.1'), equals([-0.1]));
      expect(_match('{float}', '-.10000001'), equals([-0.10000001]));
      expect(_match('{float}', '1E1'), equals([1e1]));
      expect(_match('{float}', '.1E1'), equals([1.0]));
      expect(_match('{float}', 'E1'), isNull);
      expect(_match('{float}', '-.1E-1'), equals([-0.01]));
      expect(_match('{float}', '-.1E-2'), equals([-0.001]));
      expect(_match('{float}', '-.1E+1'), equals([-1.0]));
      expect(_match('{float}', '-.1E+2'), equals([-10.0]));
      expect(_match('{float}', '-.1E1'), equals([-1.0]));
      expect(_match('{float}', '-.10E2'), equals([-10.0]));
    });

    test('matches float with zero', () {
      expect(_match('{float}', '0'), equals([0.0]));
    });

    test('exposes source', () {
      const expr = 'I have {int} cuke(s)';
      expect(
        CucumberExpression(expr, ParameterTypeRegistry()).source,
        equals(expr),
      );
    });

    test('unmatched optional groups have null values', () {
      final parameterTypeRegistry = ParameterTypeRegistry();
      parameterTypeRegistry.defineParameterType(
        ParameterType<List<String?>>(
          'textAndOrNumber',
          RegExp('([A-Z]+)?(?: )?([0-9]+)?'),
          null,
          (s) => [
            if (s.isNotEmpty) s[0] else null,
            if (s.length > 1) s[1] else null
          ],
          useForSnippets: false,
          preferForRegexpMatch: true,
        ),
      );
      final expression =
          CucumberExpression('{textAndOrNumber}', parameterTypeRegistry);

      expect(
        expression.match('TLA')?[0].getValue(),
        equals(['TLA', null]),
      );
      expect(
        expression.match('123')?[0].getValue(),
        equals([null, '123']),
      );
    });
  });
}
