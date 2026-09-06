import 'package:cucumber_expressions/src/define_default_parameter_types.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

/// A registry of [ParameterType]s, seeded with the built-in types and used to
/// resolve parameter references in expressions.
class ParameterTypeRegistry {
  /// Creates a registry populated with the default parameter types.
  ParameterTypeRegistry() {
    defineDefaultParameterTypes(defineParameterType);
  }

  final Map<String, ParameterType<Object?>> _parameterTypeByName = {};
  final Map<String, List<ParameterType<Object?>>> _parameterTypesByRegexp = {};

  /// Registers [parameterType] for use in expressions.
  ///
  /// Throws [CucumberExpressionException] if its name is already registered or
  /// if it conflicts with another preferential type for the same regexp.
  void defineParameterType<T>(ParameterType<T> parameterType) {
    final name = parameterType.name;
    if (name != null) {
      if (_parameterTypeByName.containsKey(name)) {
        if (name.isEmpty) {
          throw CucumberExpressionException(
            'The anonymous parameter type has already been defined',
          );
        } else {
          throw CucumberExpressionException(
            'There is already a parameter type with name $name',
          );
        }
      }
      _parameterTypeByName[name] = parameterType;
    }

    for (final parameterTypeRegexp in parameterType.regexpStrings) {
      final parameterTypes = _parameterTypesByRegexp.putIfAbsent(
        parameterTypeRegexp,
        () => <ParameterType<Object?>>[],
      );
      final existingParameterType =
          parameterTypes.isNotEmpty ? parameterTypes[0] : null;
      if (parameterTypes.isNotEmpty &&
          existingParameterType!.preferForRegexpMatch &&
          parameterType.preferForRegexpMatch) {
        throw CucumberExpressionException(
          'There can only be one preferential parameter type per regexp. '
          'The regexp /$parameterTypeRegexp/ is used for two preferential '
          'parameter types, {${existingParameterType.name}} and '
          '{${parameterType.name}}',
        );
      }
      if (!parameterTypes.contains(parameterType)) {
        parameterTypes
          ..add(parameterType)
          ..sort(compareParameterTypes);
      }
    }
  }
}

Iterable<ParameterType<Object?>> registeredParameterTypes(
  ParameterTypeRegistry registry,
) {
  return registry._parameterTypeByName.values;
}

ParameterType<Object?>? registeredParameterTypeByName(
  ParameterTypeRegistry registry,
  String typeName,
) {
  return registry._parameterTypeByName[typeName];
}

List<ParameterType<Object?>>? registeredParameterTypesByRegexp(
  ParameterTypeRegistry registry,
  String parameterTypeRegexp,
) {
  return registry._parameterTypesByRegexp[parameterTypeRegexp];
}
