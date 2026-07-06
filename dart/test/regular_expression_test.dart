import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'test_data_dir.dart';

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
  group('RegularExpression (conformance)', () {
    for (final file
        in yamlFilesIn('$testDataDir/regular-expression/matching')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('matches ${file.path}', () {
        final expression = expectation['expression'] as String;
        final text = expectation['text'] as String;
        final registry = ParameterTypeRegistry();
        final regularExpression =
            RegularExpression(RegExp(expression), registry);
        final matches = regularExpression.match(text);
        final actual = matches?.map((a) => normalize(a.getValue())).toList();
        final expected = normalizeExpected(expectation['expected_args']);
        expect(actual, equals(expected));
      });
    }
  });

  group('RegularExpression', () {
    List<Object?>? match(RegExp regexp, String text) {
      final regularExpression =
          RegularExpression(regexp, ParameterTypeRegistry());
      final args = regularExpression.match(text);
      return args?.map((a) => a.getValue()).toList();
    }

    test('does no transform by default', () {
      expect(match(RegExp(r'(\d\d)'), '22'), equals(['22']));
    });

    test('transforms int to int', () {
      expect(match(RegExp(r'(\d\d)'), '22'), equals(['22']));
    });

    test('transforms with builtin int type', () {
      expect(match(RegExp(r'(-?\d+)'), '22'), equals([22]));
    });

    test('matches empty string', () {
      expect(
          match(RegExp(r'^The value equals "([^"]*)"$'), 'The value equals ""'),
          equals(['']));
    });

    test('exposes source', () {
      final regexp = r'I have (\d+) cukes? in my (.+) now';
      final regularExpression =
          RegularExpression(RegExp(regexp), ParameterTypeRegistry());
      expect(regularExpression.source, equals(regexp));
    });
  });
}
