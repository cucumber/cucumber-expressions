import 'package:cucumber_expressions/src/generated_expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

// 256 generated expressions ought to be enough for anybody
const int _maxExpressions = 256;

/// Generates all combinations of [GeneratedExpression]s from an expression
/// template and the possible parameter types for each placeholder.
class CombinatorialGeneratedExpressionFactory {
  /// Creates a factory for the given [_expressionTemplate] and the possible
  /// [_parameterTypeCombinations] for each placeholder in the template.
  CombinatorialGeneratedExpressionFactory(
    this._expressionTemplate,
    this._parameterTypeCombinations,
  );

  final String _expressionTemplate;
  final List<List<ParameterType<Object?>>> _parameterTypeCombinations;

  /// Generates every combination of parameter types, up to a fixed limit.
  List<GeneratedExpression> generateExpressions() {
    final generatedExpressions = <GeneratedExpression>[];
    _generatePermutations(generatedExpressions, 0, <ParameterType<Object?>>[]);
    return generatedExpressions;
  }

  void _generatePermutations(
    List<GeneratedExpression> generatedExpressions,
    int depth,
    List<ParameterType<Object?>> currentParameterTypes,
  ) {
    if (generatedExpressions.length >= _maxExpressions) {
      return;
    }

    if (depth == _parameterTypeCombinations.length) {
      generatedExpressions.add(
        createGeneratedExpression(_expressionTemplate, currentParameterTypes),
      );
      return;
    }

    for (var i = 0; i < _parameterTypeCombinations[depth].length; ++i) {
      // Avoid recursion if no elements can be added.
      if (generatedExpressions.length >= _maxExpressions) {
        return;
      }

      final newCurrentParameterTypes =
          List<ParameterType<Object?>>.from(currentParameterTypes)
            ..add(_parameterTypeCombinations[depth][i]);
      _generatePermutations(
        generatedExpressions,
        depth + 1,
        newCurrentParameterTypes,
      );
    }
  }
}
