import 'package:cucumber_expressions/cucumber_expressions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../support/test_data_dir.dart';

void main() {
  group('CucumberExpression transformation', () {
    for (final file
        in yamlFilesIn('$testDataDir/cucumber-expression/transformation')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('transforms ${file.path}', () {
        final expression = expectation['expression'] as String;
        final expected = expectation['expected_regex'] as String;
        final cucumberExpression = ExpressionFactory(ParameterTypeRegistry())
            .createExpression(expression);
        expect(cucumberExpression.regexp.pattern, equals(expected));
      });
    }
  });
}
