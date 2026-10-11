import 'package:cucumber_expressions/src/ast.dart';
import 'package:cucumber_expressions/src/cucumber_expression_parser.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../support/test_data_dir.dart';

Map<String, Object?> astToMap(Node node) {
  final map = <String, Object?>{
    'type': node.type.value,
    'start': node.start,
    'end': node.end,
  };
  final nodes = node.nodes;
  if (nodes != null) {
    map['nodes'] = nodes.map(astToMap).toList();
  } else {
    map['token'] = node.token;
  }
  return map;
}

Map<String, Object?> yamlAstToMap(YamlMap yaml) {
  final map = <String, Object?>{
    'type': yaml['type'],
    'start': yaml['start'],
    'end': yaml['end'],
  };
  if (yaml['nodes'] != null) {
    map['nodes'] = (yaml['nodes'] as YamlList)
        .map((n) => yamlAstToMap(n as YamlMap))
        .toList();
  } else {
    map['token'] = yaml['token'];
  }
  return map;
}

void main() {
  group('CucumberExpressionParser', () {
    for (final file in yamlFilesIn('$testDataDir/cucumber-expression/parser')) {
      final expectation = loadYaml(file.readAsStringSync()) as YamlMap;
      test('parses ${file.path}', () {
        final expression = expectation['expression'] as String;
        if (expectation['expected_ast'] != null) {
          final node = CucumberExpressionParser().parse(expression);
          expect(
            astToMap(node),
            equals(yamlAstToMap(expectation['expected_ast'] as YamlMap)),
          );
        } else if (expectation['exception'] != null) {
          expect(
            () => CucumberExpressionParser().parse(expression),
            throwsA(
              isA<CucumberExpressionException>().having(
                (e) => e.message,
                'message',
                equals(expectation['exception']),
              ),
            ),
          );
        } else {
          fail('Expectation must have expected_ast or exception');
        }
      });
    }
  });
}
