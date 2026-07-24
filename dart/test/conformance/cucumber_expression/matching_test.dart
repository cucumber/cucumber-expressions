import 'package:cucumber_expressions/cucumber_expressions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../support/fixture_normalization.dart';
import '../../support/test_data_dir.dart';

void main() {
  group('Cucumber expression conformance', () {
    for (final file
        in yamlFilesIn('$testDataDir/cucumber-expression/matching')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('matches ${file.path}', () {
        final expression = expectation['expression'] as String;
        final text = expectation['text'] as String? ?? '';
        if (expectation.containsKey('expected_args')) {
          final arguments = ExpressionFactory(ParameterTypeRegistry())
              .createExpression(expression)
              .match(text);
          expect(
            arguments
                ?.map((argument) => normalizeFixtureValue(argument.getValue()))
                .toList(),
            equals(normalizeExpectedFixtureValue(expectation['expected_args'])),
          );
        } else if (expectation['exception'] != null) {
          expect(
            () => ExpressionFactory(ParameterTypeRegistry())
                .createExpression(expression)
                .match(text),
            throwsA(
              isA<CucumberExpressionException>().having(
                (error) => error.message,
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
  });
}
