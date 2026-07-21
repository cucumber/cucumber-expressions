/// A captured group from a regular expression match, possibly with nested
/// child groups.
class Group {
  Group._(this.value, this.start, this.end, this.children);

  /// The captured text, or `null` if the group did not participate.
  final String? value;

  /// The start index of the match, or `null` for non-root groups.
  final int? start;

  /// The end index of the match, or `null` for non-root groups.
  final int? end;

  /// A group's children. Either one or more children, or `null`.
  final List<Group>? children;

  /// The values of this group's children, or `[value]` when it has no children.
  List<String?>? get values {
    return (children ?? <Group>[this]).map((g) => g.value).toList();
  }
}

/// Creates groups for the internal regular-expression tree builder.
Group buildGroup(String? value, int? start, int? end, List<Group>? children) {
  return Group._(value, start, end, children);
}
