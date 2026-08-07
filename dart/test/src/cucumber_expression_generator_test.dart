import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/cucumber_expression_generator.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:test/test.dart';

void main() {
  group('CucumberExpressionGenerator', () {
    late ParameterTypeRegistry parameterTypeRegistry;
    late CucumberExpressionGenerator generator;

    setUp(() {
      parameterTypeRegistry = ParameterTypeRegistry();
      generator = CucumberExpressionGenerator(parameterTypeRegistry);
    });

    void assertExpression(
      String expectedExpression,
      List<String> expectedParameterNames,
      String text,
    ) {
      final generatedExpression = generator.generateExpressions(text)[0];
      expect(
        generatedExpression.parameterNames,
        equals(expectedParameterNames),
      );
      expect(generatedExpression.source, equals(expectedExpression));

      final cucumberExpression =
          CucumberExpression(generatedExpression.source, parameterTypeRegistry);
      final match = cucumberExpression.match(text);
      expect(
        match,
        isNotNull,
        reason: "Expected text '$text' to match generated expression "
            "'${generatedExpression.source}'",
      );
      expect(match!.length, equals(expectedParameterNames.length));
    }

    test('documents expression generation', () {
      const undefinedStepText = 'I have 2 cucumbers and 1.5 tomato';
      final generatedExpression =
          generator.generateExpressions(undefinedStepText)[0];
      expect(
        generatedExpression.source,
        equals('I have {int} cucumbers and {float} tomato'),
      );
      expect(generatedExpression.parameterNames[0], equals('int'));
      expect(generatedExpression.parameterTypes[1].name, equals('float'));
    });

    test('generates expression for no args', () {
      assertExpression('hello', [], 'hello');
    });

    test('generates expression with escaped left parenthesis', () {
      assertExpression(r'\(iii)', [], '(iii)');
    });

    test('generates expression with escaped left curly brace', () {
      assertExpression(r'\{iii}', [], '{iii}');
    });

    test('generates expression with escaped slashes', () {
      assertExpression(
        r'The {int}\/{int}\/{int} hey',
        [
          'int',
          'int2',
          'int3',
        ],
        'The 1814/05/17 hey',
      );
    });

    test('generates expression for int float arg', () {
      assertExpression(
        'I have {int} cukes and {float} euro',
        ['int', 'float'],
        'I have 2 cukes and 1.5 euro',
      );
    });

    test('generates expression for strings', () {
      assertExpression(
        'I like {string} and {string}',
        ['string', 'string2'],
        'I like "bangers" and \'mash\'',
      );
    });

    test('generates expression with percent sign', () {
      assertExpression(
        'I am {int}%% foobar',
        ['int'],
        'I am 20%% foobar',
      );
    });

    test('generates expression for just int', () {
      assertExpression('{int}', ['int'], '99999');
    });

    test('does not generate types excluded from snippets', () {
      parameterTypeRegistry.defineParameterType(
        ParameterType<String?>(
          'internal-id',
          'reference',
          null,
          (s) => s.first,
          useForSnippets: false,
          preferForRegexpMatch: false,
        ),
      );

      expect(
        generator.generateExpressions('reference').single.source,
        'reference',
      );
    });

    test('generates all combinations when several parameter types match', () {
      parameterTypeRegistry
        ..defineParameterType(
          ParameterType<String?>(
            'currency',
            RegExp('x'),
            null,
            (s) => s.first,
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        )
        ..defineParameterType(
          ParameterType<String?>(
            'date',
            RegExp('x'),
            null,
            (s) => s.first,
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        );

      final generatedExpressions =
          generator.generateExpressions('I have x and x and another x');
      final expressions = generatedExpressions.map((e) => e.source).toList();
      expect(
        expressions,
        equals([
          'I have {currency} and {currency} and another {currency}',
          'I have {currency} and {currency} and another {date}',
          'I have {currency} and {date} and another {currency}',
          'I have {currency} and {date} and another {date}',
          'I have {date} and {currency} and another {currency}',
          'I have {date} and {currency} and another {date}',
          'I have {date} and {date} and another {currency}',
          'I have {date} and {date} and another {date}',
        ]),
      );
    });

    test('exposes parameter type names in generated expression', () {
      final expression =
          generator.generateExpressions('I have 2 cukes and 1.5 euro')[0];
      final typeNames = expression.parameterTypes.map((p) => p.name).toList();
      expect(typeNames, equals(['int', 'float']));
    });

    test('generates at most 256 expressions', () {
      for (var i = 0; i < 4; i++) {
        parameterTypeRegistry.defineParameterType(
          ParameterType<String?>(
            'my-type-$i',
            RegExp('([a-z] )*?[a-z]'),
            null,
            (s) => s.first,
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        );
      }
      final expressions =
          generator.generateExpressions('a s i m p l e s t e p');
      expect(expressions.length, equals(256));
    });

    test('prefers expression with longest non empty match', () {
      parameterTypeRegistry
        ..defineParameterType(
          ParameterType<String?>(
            'zero-or-more',
            RegExp('[a-z]*'),
            null,
            (s) => s.first,
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        )
        ..defineParameterType(
          ParameterType<String?>(
            'exactly-one',
            RegExp('[a-z]'),
            null,
            (s) => s.first,
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        );

      final expressions = generator.generateExpressions('a simple step');
      expect(expressions.length, equals(2));
      expect(
        expressions[0].source,
        equals('{exactly-one} {zero-or-more} {zero-or-more}'),
      );
      expect(
        expressions[1].source,
        equals('{zero-or-more} {zero-or-more} {zero-or-more}'),
      );
    });

    test('does suggest parameter that are a full word', () {
      parameterTypeRegistry.defineParameterType(
        ParameterType<String?>(
          'direction',
          RegExp('(up|down)'),
          null,
          (s) => s.first,
          useForSnippets: true,
          preferForRegexpMatch: false,
        ),
      );

      expect(
        generator.generateExpressions('When I go down the road')[0].source,
        equals('When I go {direction} the road'),
      );
      expect(
        generator.generateExpressions('When I walk up the hill')[0].source,
        equals('When I walk {direction} the hill'),
      );
      expect(
        generator
            .generateExpressions('up the hill, the road goes down')[0]
            .source,
        equals('{direction} the hill, the road goes {direction}'),
      );
    });

    test('does not consider punctuation as being part of a word', () {
      parameterTypeRegistry.defineParameterType(
        ParameterType<String?>(
          'direction',
          RegExp('(up|down)'),
          null,
          (s) => s.first,
          useForSnippets: true,
          preferForRegexpMatch: false,
        ),
      );

      expect(
        generator.generateExpressions('direction is:down')[0].source,
        equals('direction is:{direction}'),
      );
      expect(
        generator.generateExpressions('direction is down.')[0].source,
        equals('direction is {direction}.'),
      );
    });
  });
}
