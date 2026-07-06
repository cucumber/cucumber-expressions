import 'package:cucumber_expressions/src/parameter_type.dart';

/// Describes a parameter within a generated expression, used when building
/// function or method signatures for snippets.
class ParameterInfo {
  /// Creates parameter info with the given [type], [name] and [count].
  ParameterInfo({required this.type, required this.name, required this.count});

  /// The string representation of the original ParameterType type property.
  final String? type;

  /// The parameter type name.
  final String name;

  /// The number of times this name has been used so far.
  final int count;
}

/// A Cucumber Expression generated from step text, together with the parameter
/// types that fill its placeholders.
class GeneratedExpression {
  /// Creates a generated expression from [_expressionTemplate] and its
  /// [parameterTypes].
  GeneratedExpression(this._expressionTemplate, this.parameterTypes);

  final String _expressionTemplate;

  /// The parameter types filling this expression's placeholders, in order.
  final List<ParameterType<Object?>> parameterTypes;

  /// The rendered Cucumber Expression source with placeholders filled in.
  String get source => _format(
        _expressionTemplate,
        parameterTypes.map((t) => t.name ?? '').toList(),
      );

  /// Parameter names to use in generated function/method signatures.
  List<String> get parameterNames => parameterInfos
      .map((i) => '${i.name}${i.count == 1 ? '' : i.count}')
      .toList();

  /// ParameterInfo to use in generated function/method signatures.
  List<ParameterInfo> get parameterInfos {
    final usageByTypeName = <String, int>{};
    return parameterTypes
        .map((t) => _getParameterInfo(t, usageByTypeName))
        .toList();
  }
}

ParameterInfo _getParameterInfo(
  ParameterType<Object?> parameterType,
  Map<String, int> usageByName,
) {
  final name = parameterType.name ?? '';
  var counter = usageByName[name];
  counter = counter != null ? counter + 1 : 1;
  usageByName[name] = counter;
  return ParameterInfo(type: parameterType.type, name: name, count: counter);
}

final RegExp _placeholder = RegExp(r'{(\d+)}');

String _format(String pattern, List<String> args) {
  return pattern.replaceAllMapped(_placeholder, (m) {
    final index = int.parse(m.group(1)!);
    return args[index];
  });
}
