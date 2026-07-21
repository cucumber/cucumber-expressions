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

  void setNonCapturing() {
    capturing = false;
  }

  List<GroupBuilder> get children => _groupBuilders;

  void moveChildrenTo(GroupBuilder groupBuilder) {
    _groupBuilders.forEach(groupBuilder.add);
  }
}
