import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

/// A single matched argument, pairing a captured [Group] with the
/// [ParameterType] that describes how to transform it into a value.
class Argument<T> {
  Argument._(this.group, this.parameterType);

  /// The captured group this argument was matched from.
  final Group group;

  /// The parameter type used to transform the captured group into a value.
  final ParameterType<T> parameterType;

  /// Get the value returned by the parameter type's transformer function.
  T getValue() {
    final groupValues = group.values ?? <String?>[];
    return parameterType.transform(groupValues);
  }
}

/// Builds arguments for the internal expression implementations.
List<Argument<Object?>> buildArguments(
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
      Argument<Object?>._(argGroups[i], parameterTypes[i]),
  ];
}
