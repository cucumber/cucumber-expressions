import 'package:cucumber_expressions/src/cucumber_expression_generator.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';

/// Resolves parameter types for the internal expression implementations.
ParameterType<Object?>? lookupParameterTypeByName(
  ParameterTypeRegistry registry,
  String typeName,
) {
  return registeredParameterTypeByName(registry, typeName);
}

/// Resolves a parameter type for the internal regular-expression matcher.
ParameterType<Object?>? lookupParameterTypeByRegexp(
  ParameterTypeRegistry registry,
  String parameterTypeRegexp,
  RegExp expressionRegexp,
  String text,
) {
  final parameterTypes = registeredParameterTypesByRegexp(
    registry,
    parameterTypeRegexp,
  );
  if (parameterTypes == null) {
    return null;
  }
  if (parameterTypes.length > 1 && !parameterTypes[0].preferForRegexpMatch) {
    // We don't do this check on insertion because ambiguity only matters to
    // regular expressions; Cucumber Expressions identify their type by name.
    final generatedExpressions = generateExpressionsForParameterTypes(
      text,
      parameterTypes.cast,
    );
    throw ambiguousParameterTypeExceptionForRegexp(
      parameterTypeRegexp,
      expressionRegexp,
      parameterTypes,
      generatedExpressions,
    );
  }
  return parameterTypes[0];
}
