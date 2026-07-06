import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

class Argument<T> {
  Argument(this.group, this.parameterType);

  final Group group;
  final ParameterType<T> parameterType;

  static List<Argument<Object?>> build(
    Group group,
    List<ParameterType<Object?>> parameterTypes,
  ) {
    final argGroups = group.children ?? <Group>[];

    if (argGroups.length != parameterTypes.length) {
      throw CucumberExpressionException(
        'Group has ${argGroups.length} capture groups '
        '(${argGroups.map((g) => g.value).toList()}), but there were '
        '${parameterTypes.length} parameter types '
        '(${parameterTypes.map((p) => p.name).toList()})',
      );
    }

    return [
      for (var i = 0; i < parameterTypes.length; i++)
        Argument<Object?>(argGroups[i], parameterTypes[i]),
    ];
  }

  /// Get the value returned by the parameter type's transformer function.
  T getValue() {
    final groupValues = group.values ?? <String?>[];
    return parameterType.transform(groupValues);
  }

  ParameterType<T> getParameterType() => parameterType;
}
