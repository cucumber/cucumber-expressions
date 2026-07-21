import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/regular_expression.dart';
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
        final arguments = RegularExpression(
          RegExp(expectation['expression'] as String),
          ParameterTypeRegistry(),
        ).match(expectation['text'] as String);
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
