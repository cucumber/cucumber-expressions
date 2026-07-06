import 'package:cucumber_expressions/src/cucumber_expression_tokenizer.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'test_data_dir.dart';

void main() {
  group('CucumberExpressionTokenizer', () {
    for (final file
        in yamlFilesIn('$testDataDir/cucumber-expression/tokenizer')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('tokenizes ${file.path}', () {
        final expression = expectation['expression'] as String;
        if (expectation['expected_tokens'] != null) {
          final tokens = CucumberExpressionTokenizer().tokenize(expression);
          final actual = tokens
              .map(
                (t) => {
                  'type': t.type.value,
                  'start': t.start,
                  'end': t.end,
                  'text': t.text,
                },
              )
              .toList();
          final expected = (expectation['expected_tokens'] as YamlList)
              .cast<YamlMap>()
              .map(
                (t) => {
                  'type': t['type'],
                  'start': t['start'],
                  'end': t['end'],
                  'text': t['text'],
                },
              )
              .toList();
          expect(actual, equals(expected));
        } else if (expectation['exception'] != null) {
          expect(
            () => CucumberExpressionTokenizer().tokenize(expression),
            throwsA(
              isA<CucumberExpressionException>().having(
                (e) => e.message,
                'message',
                equals(expectation['exception']),
              ),
            ),
          );
        } else {
          fail('Expectation must have expected_tokens or exception');
        }
      });
    }
  });
}
