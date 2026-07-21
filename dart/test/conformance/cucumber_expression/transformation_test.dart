import 'package:cucumber_expressions/src/cucumber_expression.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
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
        final cucumberExpression =
            CucumberExpression(expression, ParameterTypeRegistry());
        expect(cucumberExpression.regexp.pattern, equals(expected));
      });
    }
  });
}
