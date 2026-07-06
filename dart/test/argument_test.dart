import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/tree_regexp.dart';
import 'package:test/test.dart';

void main() {
  group('Argument', () {
    test('exposes getParameterType()', () {
      final treeRegexp = TreeRegexp.fromString('three (.*) mice');
      final parameterTypeRegistry = ParameterTypeRegistry();
      final group = treeRegexp.match('three blind mice')!;
      final args = Argument.build(
        group,
        [parameterTypeRegistry.lookupByTypeName('string')!],
      );
      final argument = args[0];
      expect(argument.getParameterType().name, equals('string'));
    });
  });
}
