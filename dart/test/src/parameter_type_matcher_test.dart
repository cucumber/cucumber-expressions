import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_matcher.dart';
import 'package:test/test.dart';

final type = ParameterType<String?>(
    'direction', 'up|down', 'String', (values) => values.first);

void main() {
  group('ParameterTypeMatcher', () {
    test('requires a non-empty full-word match', () {
      expect(
          ParameterTypeMatcher(type, 'up|down', 'go down!').advanceTo(0).group,
          'down');
      expect(ParameterTypeMatcher(type, 'up|down', 'setup').advanceTo(0).find,
          isFalse);
      expect(ParameterTypeMatcher(type, 'a*', 'a').find, isTrue);
      expect(ParameterTypeMatcher(type, 'a*', '').find, isFalse);
    });

    test('sorts earlier and longer matches first', () {
      final early = ParameterTypeMatcher(type, 'up', 'up then down');
      final late = ParameterTypeMatcher(type, 'down', 'up then down');
      final long = ParameterTypeMatcher(type, 'up then', 'up then down');
      expect(ParameterTypeMatcher.compare(early, late), lessThan(0));
      expect(ParameterTypeMatcher.compare(long, early), lessThan(0));
    });
  });
}
