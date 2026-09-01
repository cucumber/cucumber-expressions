import 'package:cucumber_expressions/cucumber_expressions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../support/fixture_normalization.dart';
import '../../support/test_data_dir.dart';

void main() {
  group('Regular expression conformance', () {
    for (final file
        in yamlFilesIn('$testDataDir/regular-expression/matching')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('matches ${file.path}', () {
        final arguments = ExpressionFactory(ParameterTypeRegistry())
            .createExpression(RegExp(expectation['expression'] as String))
            .match(expectation['text'] as String);
        expect(
          arguments
              ?.map((argument) => normalizeFixtureValue(argument.getValue()))
              .toList(),
          equals(normalizeExpectedFixtureValue(expectation['expected_args'])),
        );
      });
    }
  });
}
