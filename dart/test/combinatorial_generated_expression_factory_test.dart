import 'package:cucumber_expressions/src/combinatorial_generated_expression_factory.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:test/test.dart';

void main() {
  group('CombinatorialGeneratedExpressionFactory', () {
    test('generates multiple expressions', () {
      final parameterTypeCombinations = <List<ParameterType<Object?>>>[
        [
          ParameterType<String?>(
              'color', RegExp('red|blue|yellow'), null, (s) => s.first,
              useForSnippets: false, preferForRegexpMatch: true),
          ParameterType<String?>(
              'csscolor', RegExp('red|blue|yellow'), null, (s) => s.first,
              useForSnippets: false, preferForRegexpMatch: true),
        ],
        [
          ParameterType<String?>(
              'date', RegExp(r'\d{4}-\d{2}-\d{2}'), null, (s) => s.first,
              useForSnippets: false, preferForRegexpMatch: true),
          ParameterType<String?>(
              'datetime', RegExp(r'\d{4}-\d{2}-\d{2}'), null, (s) => s.first,
              useForSnippets: false, preferForRegexpMatch: true),
          ParameterType<String?>(
              'timestamp', RegExp(r'\d{4}-\d{2}-\d{2}'), null, (s) => s.first,
              useForSnippets: false, preferForRegexpMatch: true),
        ],
      ];

      final factory = CombinatorialGeneratedExpressionFactory(
        'I bought a {{0}} ball on {{1}}',
        parameterTypeCombinations,
      );
      final expressions =
          factory.generateExpressions().map((ge) => ge.source).toList();
      expect(
        expressions,
        equals([
          'I bought a {color} ball on {date}',
          'I bought a {color} ball on {datetime}',
          'I bought a {color} ball on {timestamp}',
          'I bought a {csscolor} ball on {date}',
          'I bought a {csscolor} ball on {datetime}',
          'I bought a {csscolor} ball on {timestamp}',
        ]),
      );
    });
  });
}
