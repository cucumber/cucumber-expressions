import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/group.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

/// A single matched argument, pairing a captured [Group] with the
/// [ParameterType] that describes how to transform it into a value.
class Argument<T> {
  /// Creates an [Argument] for the given [group] and [parameterType].
  Argument(this.group, this.parameterType);

  /// The captured group this argument was matched from.
  final Group group;

  /// The parameter type used to transform the captured group into a value.
  final ParameterType<T> parameterType;

  /// Builds an argument for each child of [group], pairing it with the
  /// corresponding entry in [parameterTypes].
  ///
  /// Throws a [CucumberExpressionException] if the number of capture groups
  /// does not match the number of parameter types.
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
}
