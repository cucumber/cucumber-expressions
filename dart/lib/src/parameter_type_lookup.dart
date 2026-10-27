import 'package:cucumber_expressions/src/cucumber_expression_generator.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';

/// The parameter type in [registry] named [typeName], or `null` if there is
/// none.
ParameterType<Object?>? lookupParameterTypeByName(
  ParameterTypeRegistry registry,
  String typeName,
) {
  return registeredParameterTypeByName(registry, typeName);
}

/// The parameter type in [registry] for the capture group pattern
/// [parameterTypeRegexp], or `null` if there is none.
///
/// When several parameter types use the pattern, the preferential one is
/// returned. Throws an [AmbiguousParameterTypeException] when none of them
/// is preferential. [expressionRegexp] and [text] are used to build its
/// message.
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
