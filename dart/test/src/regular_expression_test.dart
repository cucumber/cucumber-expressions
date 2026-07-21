import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';
import 'package:test/test.dart';

List<Object?>? match(RegExp regexp, String text,
        [ParameterTypeRegistry? registry]) =>
    RegularExpression(regexp, registry ?? ParameterTypeRegistry())
        .match(text)
        ?.map((argument) => argument.getValue())
        .toList();

void main() {
  group('RegularExpression', () {
    test('uses strings for unregistered captures', () {
      expect(match(RegExp(r'(\d\d)'), '22'), equals(['22']));
    });

    test('uses matching built-in parameter types', () {
      expect(match(RegExp(r'(-?\d+)'), '22'), equals([22]));
    });

    test('preserves empty captures and returns null when unmatched', () {
      expect(
          match(RegExp(r'^The value equals "([^"]*)"$'), 'The value equals ""'),
          ['']);
      expect(match(RegExp(r'(\d+)'), 'no number'), isNull);
    });

    test('uses custom parameter types for matching captures', () {
      final registry = ParameterTypeRegistry()
        ..defineParameterType(
          ParameterType<String?>(
            'color',
            'red|blue|yellow',
            'Color',
            (values) => 'color:${values.first}',
            useForSnippets: false,
            preferForRegexpMatch: true,
          ),
        );
      expect(
          match(RegExp(r'I have a (red|blue|yellow) ball'), 'I have a red ball',
              registry),
          ['color:red']);
    });

    test('reports ambiguous non-preferential parameter types', () {
      final registry = ParameterTypeRegistry()
        ..defineParameterType(ParameterType<String?>(
            'color', 'red|blue', 'Color', (v) => v.first))
        ..defineParameterType(ParameterType<String?>(
            'shade', 'red|blue', 'Shade', (v) => v.first));

      expect(
        () => match(RegExp(r'(red|blue)'), 'red', registry),
        throwsA(isA<AmbiguousParameterTypeException>()),
      );
    });

    test('exposes its source', () {
      const source = r'I have (\d+) cukes?';
      expect(RegularExpression(RegExp(source), ParameterTypeRegistry()).source,
          source);
    });
  });
}
