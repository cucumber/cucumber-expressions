import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/group_builder.dart';

/// Wraps a [RegExp] and builds a tree of capture [Group]s that mirrors the
/// nesting of the regular expression's groups.
class TreeRegexp {
  /// Creates a tree regexp from an existing [regexp].
  TreeRegexp(this.regexp) : groupBuilder = _createGroupBuilder(regexp);

  /// Creates a tree regexp by compiling [pattern].
  TreeRegexp.fromString(String pattern) : this(RegExp(pattern));

  /// The underlying regular expression.
  final RegExp regexp;

  /// The root group builder describing the capture group structure.
  final GroupBuilder groupBuilder;

  static GroupBuilder _createGroupBuilder(RegExp regexp) {
    final source = regexp.pattern;
    final stack = <GroupBuilder>[GroupBuilder()];
    final groupStartStack = <int>[];
    var escaping = false;
    var charClass = false;

    for (var i = 0; i < source.length; i++) {
      final c = source[i];
      if (c == '[' && !escaping) {
        charClass = true;
      } else if (c == ']' && !escaping) {
        charClass = false;
      } else if (c == '(' && !escaping && !charClass) {
        groupStartStack.add(i);
        final nonCapturing = _isNonCapturing(source, i);
        final groupBuilder = GroupBuilder();
        if (nonCapturing) {
          groupBuilder.setNonCapturing();
        }
        stack.add(groupBuilder);
      } else if (c == ')' && !escaping && !charClass) {
        final gb = stack.removeLast();
        final groupStart = groupStartStack.removeLast();
        if (gb.capturing) {
          gb.source = source.substring(groupStart + 1, i);
          stack.last.add(gb);
        } else {
          gb.moveChildrenTo(stack.last);
        }
      }
      escaping = c == r'\' && !escaping;
    }
    return stack.removeLast();
  }

  static bool _isNonCapturing(String source, int i) {
    // Regex is valid. Bounds check not required.
    if (i + 1 >= source.length || source[i + 1] != '?') {
      // (X)
      return false;
    }
    if (i + 2 >= source.length || source[i + 2] != '<') {
      // (?:X)
      // (?=X)
      // (?!X)
      return true;
    }
    // (?<=X) or (?<!X) else (?<name>X)
    return source[i + 3] == '=' || source[i + 3] == '!';
  }

  /// Matches [s] and returns the root [Group], or `null` if there is no match.
  Group? match(String s) {
    final match = regexp.firstMatch(s);
    if (match == null) {
      return null;
    }
    var groupIndex = 0;
    int nextGroupIndex() => groupIndex++;
    return groupBuilder.build(match, nextGroupIndex);
  }
}
