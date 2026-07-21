import 'package:cucumber_expressions/src/group.dart';

/// Builds a tree of [Group]s from a regular expression's capture group
/// structure.
class GroupBuilder {
  /// The regular expression source for this group.
  String source = '';

  /// Whether this group is a capturing group.
  bool capturing = true;
  final List<GroupBuilder> _groupBuilders = <GroupBuilder>[];

  /// Adds [groupBuilder] as a child of this builder.
  void add(GroupBuilder groupBuilder) {
    _groupBuilders.add(groupBuilder);
  }

  /// Builds a [Group] from [match], assigning group indices via
  /// [nextGroupIndex].
  Group build(RegExpMatch match, int Function() nextGroupIndex) {
    final groupIndex = nextGroupIndex();
    final children =
        _groupBuilders.map((gb) => gb.build(match, nextGroupIndex)).toList();
    final value = match.group(groupIndex);
    int? start;
    int? end;
    if (value != null) {
      start = match.start;
      end = match.end;
    }
    return buildGroup(
      value,
      groupIndex == 0 ? start : null,
      groupIndex == 0 ? end : null,
      children.isEmpty ? null : children,
    );
  }

  /// Marks this group as non-capturing.
  void setNonCapturing() {
    capturing = false;
  }

  /// The child group builders of this builder.
  List<GroupBuilder> get children => _groupBuilders;

  /// Moves this builder's children into [groupBuilder].
  void moveChildrenTo(GroupBuilder groupBuilder) {
    _groupBuilders.forEach(groupBuilder.add);
  }
}
