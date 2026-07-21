import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_lookup.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterType', () {
    test('does not allow ignore flag on regexp', () {
      expect(
        () => ParameterType<String?>(
          'case-insensitive',
          RegExp('[a-z]+', caseSensitive: false),
          'String',
          (s) => s.first,
          useForSnippets: true,
          preferForRegexpMatch: true,
        ),
        throwsA(
          isA<CucumberExpressionException>().having(
            (e) => e.message,
            'message',
            equals("ParameterType Regexps can't use flag 'i'"),
          ),
        ),
      );
    });

    test('does not allow multiline flag on regexp', () {
      expect(
        () => ParameterType<String?>(
          'multiline',
          RegExp('[a-z]+', multiLine: true),
          'String',
          (values) => values.first,
        ),
        throwsA(
          isA<CucumberExpressionException>().having(
            (error) => error.message,
            'message',
            equals("ParameterType Regexps can't use flag 'm'"),
          ),
        ),
      );
    });

    test('normalizes string, regexp, and list regexp definitions', () {
      expect(
        ParameterType<String?>(
            'word', r'\w+', 'String', (values) => values.first).regexpStrings,
        [r'\w+'],
      );
      expect(
        ParameterType<String?>(
          'wordOrDigit',
          [RegExp(r'\w+'), r'\d+'],
          'String',
          (values) => values.first,
        ).regexpStrings,
        [r'\w+', r'\d+'],
      );
    });

    test('rejects illegal parameter-name syntax', () {
      for (final name in ['[word]', 'word.name', 'word(name)']) {
        expect(
          () => ParameterType<String?>(
              name, '.*', 'String', (values) => values.first),
          throwsA(isA<CucumberExpressionException>()),
        );
      }
    });

    test('preserves registered type names', () {
      final r = ParameterTypeRegistry();
      expect(lookupParameterTypeByName(r, 'int')!.type, 'int');
      expect(lookupParameterTypeByName(r, 'biginteger')!.type, 'BigInt');
      expect(lookupParameterTypeByName(r, 'word')!.type, 'String');
    });
  });
}
