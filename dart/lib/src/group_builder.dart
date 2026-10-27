import 'package:cucumber_expressions/src/group.dart';

/// Describes one group in a regular expression and the capturing groups
/// nested inside it, so that a match can be turned into a [Group] tree.
class GroupBuilder {
  /// The pattern inside this group's parentheses.
  String source = '';

  /// Whether this group captures text.
  bool capturing = true;
  final List<GroupBuilder> _groupBuilders = <GroupBuilder>[];

  /// Adds [groupBuilder] as a nested capturing group.
  void add(GroupBuilder groupBuilder) {
    _groupBuilders.add(groupBuilder);
  }

  /// Builds the [Group] tree for [match].
  ///
  /// [nextGroupIndex] returns the next capture group index each time it is
  /// called. It is called once for this builder and once for each nested
  /// builder, in source order.
  Group build(RegExpMatch match, int Function() nextGroupIndex) {
    final groupIndex = nextGroupIndex();
    final children = _groupBuilders
        .map((gb) => gb.build(match, nextGroupIndex))
        .toList();
    // RegExpMatch only exposes the indices of the overall match.
    final isRoot = groupIndex == 0;
    return buildGroup(
      match.group(groupIndex),
      isRoot ? match.start : null,
      isRoot ? match.end : null,
      children.isEmpty ? null : children,
    );
  }

  /// Marks this group as non-capturing.
  void setNonCapturing() {
    capturing = false;
  }

  /// The nested capturing groups.
  List<GroupBuilder> get children => _groupBuilders;

  /// Adds this group's nested groups to [groupBuilder].
  void moveChildrenTo(GroupBuilder groupBuilder) {
    _groupBuilders.forEach(groupBuilder.add);
  }
}
