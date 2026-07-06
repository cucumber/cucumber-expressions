import 'package:cucumber_expressions/src/tree_regexp.dart';
import 'package:test/test.dart';

void main() {
  group('TreeRegexp', () {
    test('exposes group source', () {
      final tr = TreeRegexp(RegExp('(a(?:b)?)(c)'));
      expect(
        tr.groupBuilder.children.map((gb) => gb.source).toList(),
        equals(['a(?:b)?', 'c']),
      );
    });

    test('builds tree', () {
      final tr = TreeRegexp(RegExp('(a(?:b)?)(c)'));
      final group = tr.match('ac')!;
      expect(group.value, equals('ac'));
      expect(group.children![0].value, equals('a'));
      expect(group.children![0].children, isNull);
      expect(group.children![1].value, equals('c'));
    });

    test('ignores ?: as a non-capturing group', () {
      final tr = TreeRegexp(RegExp('a(?:b)(c)'));
      final group = tr.match('abc')!;
      expect(group.value, equals('abc'));
      expect(group.children!.length, equals(1));
    });

    test('ignores ?! as a non-capturing group', () {
      final tr = TreeRegexp(RegExp('a(?!b)(.+)'));
      final group = tr.match('aBc')!;
      expect(group.value, equals('aBc'));
      expect(group.children!.length, equals(1));
    });

    test('ignores ?= as a non-capturing group', () {
      final tr = TreeRegexp(RegExp('a(?=[b])(.+)'));
      final group = tr.match('abc')!;
      expect(group.value, equals('abc'));
      expect(group.children!.length, equals(1));
      expect(group.children![0].value, equals('bc'));
    });

    test('ignores ?<= as a non-capturing group', () {
      final tr = TreeRegexp(RegExp(r'a(.+)(?<=c)$'));
      final group = tr.match('abc')!;
      expect(group.value, equals('abc'));
      expect(group.children!.length, equals(1));
      expect(group.children![0].value, equals('bc'));
    });

    test('ignores ?<! as a non-capturing group', () {
      final tr = TreeRegexp(RegExp(r'a(.+?)(?<!b)$'));
      final group = tr.match('abc')!;
      expect(group.value, equals('abc'));
      expect(group.children!.length, equals(1));
      expect(group.children![0].value, equals('bc'));
    });

    test('matches named capturing group', () {
      final tr = TreeRegexp(RegExp('a(?<name>b)c'));
      final group = tr.match('abc')!;
      expect(group.value, equals('abc'));
      expect(group.children!.length, equals(1));
      expect(group.children![0].value, equals('b'));
    });

    test('matches optional group', () {
      final tr = TreeRegexp(RegExp('^Something( with an optional argument)?'));
      final group = tr.match('Something')!;
      expect(group.children![0].value, isNull);
    });

    test('matches nested groups', () {
      final tr = TreeRegexp(RegExp(
          r'^A (\d+) thick line from ((\d+),\s*(\d+),\s*(\d+)) to ((\d+),\s*(\d+),\s*(\d+))'));
      final group = tr.match('A 5 thick line from 10,20,30 to 40,50,60')!;
      expect(group.children![0].value, equals('5'));
      expect(group.children![1].value, equals('10,20,30'));
      expect(group.children![1].children![0].value, equals('10'));
      expect(group.children![1].children![1].value, equals('20'));
      expect(group.children![1].children![2].value, equals('30'));
      expect(group.children![2].value, equals('40,50,60'));
      expect(group.children![2].children![0].value, equals('40'));
      expect(group.children![2].children![1].value, equals('50'));
      expect(group.children![2].children![2].value, equals('60'));
    });

    test('detects multiple non capturing groups', () {
      final tr = TreeRegexp(RegExp(r'(?:a)(:b)(\?c)(d)'));
      final group = tr.match('a:b?cd')!;
      expect(group.children!.length, equals(3));
    });

    test('works with escaped backslash', () {
      final tr = TreeRegexp(RegExp(r'foo\\(bar|baz)'));
      final group = tr.match('foo\\bar')!;
      expect(group.children!.length, equals(1));
    });

    test('works with escaped slash', () {
      final tr = TreeRegexp(RegExp(r"^I go to '\/(.+)'$"));
      final group = tr.match("I go to '/hello'")!;
      expect(group.children!.length, equals(1));
    });

    test('works with digit and word', () {
      final tr = TreeRegexp(RegExp(r'^(\d) (\w+)$'));
      final group = tr.match('2 you')!;
      expect(group.children!.length, equals(2));
    });

    test('captures non capturing groups with capturing groups inside', () {
      final tr = TreeRegexp.fromString('the stdout(?: from "(.*?)")?');
      final group = tr.match('the stdout')!;
      expect(group.value, equals('the stdout'));
      expect(group.children![0].value, isNull);
      expect(group.children!.length, equals(1));
    });

    test('works with case insensitive flag', () {
      final tr = TreeRegexp(RegExp('HELLO', caseSensitive: false));
      final group = tr.match('hello')!;
      expect(group.value, equals('hello'));
    });

    test('empty capturing group', () {
      final tr = TreeRegexp(RegExp('()'));
      final group = tr.match('')!;
      expect(group.value, equals(''));
      expect(group.children!.length, equals(1));
    });

    test('empty look ahead', () {
      final tr = TreeRegexp(RegExp('(?<=)'));
      final group = tr.match('')!;
      expect(group.value, equals(''));
      expect(group.children, isNull);
    });

    test('does not consider parenthesis in character class as group', () {
      final tr = TreeRegexp(RegExp(r'^drawings: ([A-Z, ()]+)$'));
      final group = tr.match('drawings: ONE(TWO)')!;
      expect(group.value, equals('drawings: ONE(TWO)'));
      expect(group.children!.length, equals(1));
      expect(group.children![0].value, equals('ONE(TWO)'));
    });
  });
}
