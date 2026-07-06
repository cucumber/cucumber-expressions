import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';
import 'package:test/test.dart';

class Color {
  Color(this.name);
  final String name;
}

class CssColor {
  CssColor(this.name);
  final String name;
}

class Coordinate {
  Coordinate(this.x, this.y, this.z);
  final int x;
  final int y;
  final int z;
}

void main() {
  group('Custom parameter type', () {
    late ParameterTypeRegistry parameterTypeRegistry;

    setUp(() {
      parameterTypeRegistry = ParameterTypeRegistry();
      parameterTypeRegistry.defineParameterType(
        ParameterType<Color>(
            'color', RegExp('red|blue|yellow'), 'Color', (s) => Color(s.first!),
            useForSnippets: false, preferForRegexpMatch: true),
      );
    });

    group('CucumberExpression', () {
      test('throws exception for illegal character in parameter name', () {
        expect(
          () => ParameterType<String?>(
              '[string]', RegExp('.*'), 'String', (s) => s.first),
          throwsA(
            isA<CucumberExpressionException>().having(
              (e) => e.message,
              'message',
              equals(
                'Illegal character in parameter name {[string]}. '
                "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'",
              ),
            ),
          ),
        );
      });

      test('matches parameters with custom parameter type', () {
        final expression =
            CucumberExpression('I have a {color} ball', parameterTypeRegistry);
        final value =
            expression.match('I have a red ball')?[0].getValue() as Color?;
        expect(value?.name, equals('red'));
      });

      test('matches parameters with multiple capture groups', () {
        parameterTypeRegistry.defineParameterType(
          ParameterType<Coordinate>(
            'coordinate',
            RegExp(r'(\d+),\s*(\d+),\s*(\d+)'),
            'Coordinate',
            (s) => Coordinate(
              int.parse(s[0]!),
              int.parse(s[1]!),
              int.parse(s[2]!),
            ),
            useForSnippets: true,
            preferForRegexpMatch: true,
          ),
        );
        final expression = CucumberExpression(
          'A {int} thick line from {coordinate} to {coordinate}',
          parameterTypeRegistry,
        );
        final args =
            expression.match('A 5 thick line from 10,20,30 to 40,50,60');

        expect(args?[0].getValue(), equals(5));

        final from = args?[1].getValue() as Coordinate?;
        expect(from?.x, equals(10));
        expect(from?.y, equals(20));
        expect(from?.z, equals(30));

        final to = args?[2].getValue() as Coordinate?;
        expect(to?.x, equals(40));
        expect(to?.y, equals(50));
        expect(to?.z, equals(60));
      });

      test('matches custom parameter type using optional capture group', () {
        parameterTypeRegistry = ParameterTypeRegistry();
        parameterTypeRegistry.defineParameterType(
          ParameterType<Color>(
            'color',
            [
              RegExp('red|blue|yellow'),
              RegExp('(?:dark|light) (?:red|blue|yellow)'),
            ],
            'Color',
            (s) => Color(s.first!),
            useForSnippets: false,
            preferForRegexpMatch: true,
          ),
        );
        final expression =
            CucumberExpression('I have a {color} ball', parameterTypeRegistry);
        final value =
            expression.match('I have a dark red ball')?[0].getValue() as Color?;
        expect(value?.name, equals('dark red'));
      });

      test('defers transformation until queried from argument', () {
        parameterTypeRegistry.defineParameterType(
          ParameterType<String?>(
            'throwing',
            RegExp('bad'),
            null,
            (s) => throw StateError("Can't transform [${s.first}]"),
            useForSnippets: false,
            preferForRegexpMatch: true,
          ),
        );

        final expression = CucumberExpression(
          'I have a {throwing} parameter',
          parameterTypeRegistry,
        );

        final args = expression.match('I have a bad parameter')!;
        expect(
          () => args[0].getValue(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              equals("Can't transform [bad]"),
            ),
          ),
        );
      });

      group('conflicting parameter type', () {
        test('is detected for type name', () {
          expect(
            () => parameterTypeRegistry.defineParameterType(
              ParameterType<CssColor>(
                  'color', RegExp('.*'), 'CssColor', (s) => CssColor(s.first!),
                  useForSnippets: false, preferForRegexpMatch: true),
            ),
            throwsA(
              isA<CucumberExpressionException>().having(
                (e) => e.message,
                'message',
                equals('There is already a parameter type with name color'),
              ),
            ),
          );
        });

        test('is not detected for type', () {
          parameterTypeRegistry.defineParameterType(
            ParameterType<Color>(
                'whatever', RegExp('.*'), 'Color', (s) => Color(s.first!),
                useForSnippets: false, preferForRegexpMatch: false),
          );
        });

        test('is not detected for regexp', () {
          parameterTypeRegistry.defineParameterType(
            ParameterType<CssColor>('css-color', RegExp('red|blue|yellow'),
                'CssColor', (s) => CssColor(s.first!),
                useForSnippets: true, preferForRegexpMatch: false),
          );

          expect(
            CucumberExpression(
                    'I have a {css-color} ball', parameterTypeRegistry)
                .match('I have a blue ball')?[0]
                .getValue(),
            isA<CssColor>(),
          );
          expect(
            (CucumberExpression(
                        'I have a {css-color} ball', parameterTypeRegistry)
                    .match('I have a blue ball')?[0]
                    .getValue() as CssColor?)
                ?.name,
            equals('blue'),
          );
          expect(
            CucumberExpression('I have a {color} ball', parameterTypeRegistry)
                .match('I have a blue ball')?[0]
                .getValue(),
            isA<Color>(),
          );
          expect(
            (CucumberExpression('I have a {color} ball', parameterTypeRegistry)
                    .match('I have a blue ball')?[0]
                    .getValue() as Color?)
                ?.name,
            equals('blue'),
          );
        });
      });
    });

    group('RegularExpression', () {
      test('matches arguments with custom parameter type', () {
        final expression = RegularExpression(
          RegExp('I have a (red|blue|yellow) ball'),
          parameterTypeRegistry,
        );
        final value =
            expression.match('I have a red ball')?[0].getValue() as Color?;
        expect(value, isA<Color>());
        expect(value?.name, equals('red'));
      });
    });
  });
}
