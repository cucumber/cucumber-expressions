import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/group_builder.dart';

class TreeRegexp {
  TreeRegexp(RegExp regexp) : this._(regexp, _parse(regexp.pattern));

  TreeRegexp.fromString(String pattern) : this(RegExp(pattern));

  TreeRegexp._(this.regexp, (GroupBuilder, String) parsed)
      : groupBuilder = parsed.$1,
        _indexedRegexp = RegExp(
          parsed.$2,
          multiLine: regexp.isMultiLine,
          caseSensitive: regexp.isCaseSensitive,
          unicode: regexp.isUnicode,
          dotAll: regexp.isDotAll,
        );

  final RegExp regexp;

  final GroupBuilder groupBuilder;

  final RegExp _indexedRegexp;

  static (GroupBuilder, String) _parse(String source) {
    final indexed = StringBuffer();
    final stack = <GroupBuilder>[GroupBuilder()];
    final groupStartStack = <int>[];
    var escaping = false;
    var charClass = false;

    for (var i = 0; i < source.length; i++) {
      final c = source[i];
      if (escaping && !charClass && _isBackreferenceDigit(c)) {
        var end = i + 1;
        while (end < source.length && _isDigit(source[end])) {
          end++;
        }
        indexed.write(2 * int.parse(source.substring(i, end)));
        i = end - 1;
        escaping = false;
        continue;
      }
      if (c == '[' && !escaping) {
        charClass = true;
      } else if (c == ']' && !escaping) {
        charClass = false;
      } else if (c == '(' && !escaping && !charClass) {
        groupStartStack.add(i);
        final groupBuilder = GroupBuilder();
        if (_isNonCapturing(source, i)) {
          groupBuilder.setNonCapturing();
        } else {
          indexed.write(r'(?:(?<=([\s\S]*))');
        }
        stack.add(groupBuilder);
      } else if (c == ')' && !escaping && !charClass) {
        final gb = stack.removeLast();
        final groupStart = groupStartStack.removeLast();
        if (gb.capturing) {
          gb.source = source.substring(groupStart + 1, i);
          stack.last.add(gb);
          indexed.write(')');
        } else {
          gb.moveChildrenTo(stack.last);
        }
      }
      indexed.write(c);
      escaping = c == r'\' && !escaping;
    }
    return (stack.removeLast(), indexed.toString());
  }

  static bool _isDigit(String c) => '0123456789'.contains(c);

  static bool _isBackreferenceDigit(String c) => '123456789'.contains(c);

  static bool _isNonCapturing(String source, int i) {
    if (i + 1 >= source.length || source[i + 1] != '?') {
      return false;
    }
    if (i + 2 >= source.length || source[i + 2] != '<') {
      return true;
    }
    return source[i + 3] == '=' || source[i + 3] == '!';
  }

  Group? match(String s) {
    final match = _indexedRegexp.firstMatch(s);
    if (match == null) {
      return null;
    }
    var groupIndex = 0;
    int nextGroupIndex() => groupIndex++;
    return groupBuilder.build(match, nextGroupIndex);
  }
}
