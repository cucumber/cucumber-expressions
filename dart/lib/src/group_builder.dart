import 'package:cucumber_expressions/src/group.dart';

class GroupBuilder {
  String source = '';

  bool capturing = true;
  final List<GroupBuilder> _groupBuilders = <GroupBuilder>[];

  void add(GroupBuilder groupBuilder) {
    _groupBuilders.add(groupBuilder);
  }

  Group build(RegExpMatch match, int Function() nextGroupIndex) {
    final groupIndex = nextGroupIndex();
    final children =
        _groupBuilders.map((gb) => gb.build(match, nextGroupIndex)).toList();
    // RegExpMatch only exposes the indices of the overall match.
    final isRoot = groupIndex == 0;
    return buildGroup(
      match.group(groupIndex),
      isRoot ? match.start : null,
      isRoot ? match.end : null,
      children.isEmpty ? null : children,
    );
  }

  void setNonCapturing() {
    capturing = false;
  }

  List<GroupBuilder> get children => _groupBuilders;

  void moveChildrenTo(GroupBuilder groupBuilder) {
    _groupBuilders.forEach(groupBuilder.add);
  }
}
