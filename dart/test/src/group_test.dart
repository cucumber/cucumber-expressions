import 'package:cucumber_expressions/src/group.dart';
import 'package:test/test.dart';

void main() {
  group('Group', () {
    test('uses its own value when it has no children', () {
      final group = buildGroup('value', 3, 8, null);
      expect(group.values, ['value']);
      expect(group.start, 3);
      expect(group.end, 8);
    });

    test('uses immediate child values when it has children', () {
      final group = buildGroup('parent', 0, 6, [
        buildGroup('first', null, null, null),
        buildGroup(null, null, null, null),
      ]);
      expect(group.values, ['first', null]);
    });
  });
}
