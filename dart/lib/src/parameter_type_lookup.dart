import 'package:cucumber_expressions/src/cucumber_expression_generator.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';

ParameterType<Object?>? lookupParameterTypeByName(
  ParameterTypeRegistry registry,
  String typeName,
) {
  return registeredParameterTypeByName(registry, typeName);
}

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
