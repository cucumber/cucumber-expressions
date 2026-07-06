class Group {
  Group(this.value, this.start, this.end, this.children);

  final String? value;
  final int? start;
  final int? end;

  /// A group's children. Either one or more children, or `null`.
  final List<Group>? children;

  List<String?>? get values {
    return (children ?? <Group>[this]).map((g) => g.value).toList();
  }
}
