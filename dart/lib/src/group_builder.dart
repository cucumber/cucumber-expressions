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
    final value = match.group(2 * groupIndex);
    final start = value == null
        ? null
        : groupIndex == 0
            ? match.start
            : match.group(2 * groupIndex - 1)!.length;
    return buildGroup(
      value,
      start,
      start == null ? null : start + value!.length,
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
