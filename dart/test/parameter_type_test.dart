import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
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

    test('has a type name for {int}', () {
      final r = ParameterTypeRegistry();
      final t = r.lookupByTypeName('int')!;
      expect(t.type, equals('int'));
    });

    test('has a type name for {biginteger}', () {
      final r = ParameterTypeRegistry();
      final t = r.lookupByTypeName('biginteger')!;
      expect(t.type, equals('BigInt'));
    });

    test('has a type name for {word}', () {
      final r = ParameterTypeRegistry();
      final t = r.lookupByTypeName('word')!;
      expect(t.type, equals('String'));
    });
  });
}
