import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:test/test.dart';

void main() {
  group('buildArguments', () {
    test('pairs capture groups with parameter types in order', () {
      final group =
          buildGroup('12', 0, 2, [buildGroup('12', null, null, null)]);
      final type = ParameterType<int?>(
        'int',
        r'\d+',
        'int',
        (values) => int.parse(values.single!),
      );

      expect(buildArguments(group, [type]).single.getValue(), 12);
    });

    test('rejects mismatched capture groups and parameter types', () {
      final group = buildGroup('12', 0, 2, null);
      expect(
        () => buildArguments(group, [
          ParameterType<String?>(
            'text',
            '.*',
            'String',
            (values) => values.first,
          ),
        ]),
        throwsA(isA<CucumberExpressionException>()),
      );
    });
  });
}
