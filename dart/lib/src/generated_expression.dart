import 'package:cucumber_expressions/src/parameter_type.dart';

/// A Cucumber Expression generated from step text, together with the parameter
/// types that fill its placeholders.
class GeneratedExpression {
  GeneratedExpression._(this._expressionTemplate, this.parameterTypes);

  final String _expressionTemplate;

  /// The parameter types filling this expression's placeholders, in order.
  final List<ParameterType<Object?>> parameterTypes;

  /// The rendered Cucumber Expression source with placeholders filled in.
  String get source => _format(
        _expressionTemplate,
        parameterTypes.map((t) => t.name ?? '').toList(),
      );

  /// Parameter names to use in generated function/method signatures.
  List<String> get parameterNames {
    final usageByTypeName = <String, int>{};
    return parameterTypes
        .map((t) => _parameterName(t, usageByTypeName))
        .toList();
  }
}

/// Creates generated expressions for the internal combinatorial generator.
GeneratedExpression createGeneratedExpression(
  String expressionTemplate,
  List<ParameterType<Object?>> parameterTypes,
) {
  return GeneratedExpression._(expressionTemplate, parameterTypes);
}

String _parameterName(
  ParameterType<Object?> parameterType,
  Map<String, int> usageByName,
) {
  final name = parameterType.name ?? '';
  var counter = usageByName[name];
  counter = counter != null ? counter + 1 : 1;
  usageByName[name] = counter;
  return '$name${counter == 1 ? '' : counter}';
}

final RegExp _placeholder = RegExp(r'{(\d+)}');

String _format(String pattern, List<String> args) {
  return pattern.replaceAllMapped(_placeholder, (m) {
    final index = int.parse(m.group(1)!);
    return args[index];
  });
}
