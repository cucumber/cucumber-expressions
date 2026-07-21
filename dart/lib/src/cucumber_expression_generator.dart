import 'package:cucumber_expressions/src/combinatorial_generated_expression_factory.dart';
import 'package:cucumber_expressions/src/generated_expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_matcher.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';

/// Generates candidate Cucumber Expressions for a piece of step text based on
/// the available parameter types.
class CucumberExpressionGenerator {
  /// Creates a generator using the supplied parameter type registry.
  CucumberExpressionGenerator(this._parameterTypeRegistry);

  final ParameterTypeRegistry _parameterTypeRegistry;

  /// Generates candidate expressions that would match [text].
  List<GeneratedExpression> generateExpressions(String text) {
    return generateExpressionsForParameterTypes(
      text,
      () => registeredParameterTypes(_parameterTypeRegistry),
    );
  }
}

/// Generates expressions for an internal subset of parameter types.
List<GeneratedExpression> generateExpressionsForParameterTypes(
  String text,
  Iterable<ParameterType<Object?>> Function() parameterTypes,
) {
  final parameterTypeCombinations = <List<ParameterType<Object?>>>[];
  final parameterTypeMatchers = _createParameterTypeMatchers(
    text,
    parameterTypes,
  );
  var expressionTemplate = '';
  var pos = 0;
  var counter = 0;

  while (true) {
    var matchingParameterTypeMatchers = <ParameterTypeMatcher>[];

    for (final parameterTypeMatcher in parameterTypeMatchers) {
      final advancedParameterTypeMatcher = parameterTypeMatcher.advanceTo(pos);
      if (advancedParameterTypeMatcher.find) {
        matchingParameterTypeMatchers.add(advancedParameterTypeMatcher);
      }
    }

    if (matchingParameterTypeMatchers.isNotEmpty) {
      matchingParameterTypeMatchers = matchingParameterTypeMatchers
        ..sort(ParameterTypeMatcher.compare);

      // Find all the best parameter type matchers, they are all candidates.
      final bestParameterTypeMatcher = matchingParameterTypeMatchers[0];
      final bestParameterTypeMatchers = matchingParameterTypeMatchers
          .where(
            (m) =>
                ParameterTypeMatcher.compare(m, bestParameterTypeMatcher) == 0,
          )
          .toList();

      // Build a list of parameter types without duplicates, sorted so
      // preferential parameter types are listed first.
      var parameterTypes = <ParameterType<Object?>>[];
      for (final parameterTypeMatcher in bestParameterTypeMatchers) {
        if (!parameterTypes.contains(parameterTypeMatcher.parameterType)) {
          parameterTypes.add(parameterTypeMatcher.parameterType);
        }
      }
      parameterTypes = parameterTypes..sort(compareParameterTypes);

      parameterTypeCombinations.add(parameterTypes);

      expressionTemplate +=
          _escapeText(text.substring(pos, bestParameterTypeMatcher.start));
      expressionTemplate += '{{${counter++}}}';

      pos = bestParameterTypeMatcher.start +
          bestParameterTypeMatcher.group.length;
    } else {
      break;
    }

    if (pos >= text.length) {
      break;
    }
  }

  expressionTemplate += _escapeText(text.substring(pos));
  return CombinatorialGeneratedExpressionFactory(
    expressionTemplate,
    parameterTypeCombinations,
  ).generateExpressions();
}

List<ParameterTypeMatcher> _createParameterTypeMatchers(
  String text,
  Iterable<ParameterType<Object?>> Function() parameterTypes,
) {
  var parameterMatchers = <ParameterTypeMatcher>[];
  for (final parameterType in parameterTypes()) {
    if (parameterType.useForSnippets) {
      parameterMatchers = parameterMatchers
        ..addAll(_createParameterTypeMatchers2(parameterType, text));
    }
  }
  return parameterMatchers;
}

List<ParameterTypeMatcher> _createParameterTypeMatchers2(
  ParameterType<Object?> parameterType,
  String text,
) {
  return parameterType.regexpStrings
      .map((regexp) => ParameterTypeMatcher(parameterType, regexp, text))
      .toList();
}

String _escapeText(String s) {
  return s.replaceAll('(', r'\(').replaceAll('{', r'\{').replaceAll('/', r'\/');
}
