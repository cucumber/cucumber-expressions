import 'cucumber_expression_generator.dart';
import 'define_default_parameter_types.dart';
import 'errors.dart';
import 'expression.dart';
import 'parameter_type.dart';

class ParameterTypeRegistry implements DefinesParameterType {
  ParameterTypeRegistry() {
    defineDefaultParameterTypes(this);
  }

  final Map<String, ParameterType<Object?>> _parameterTypeByName = {};
  final Map<String, List<ParameterType<Object?>>> _parameterTypesByRegexp = {};

  Iterable<ParameterType<Object?>> get parameterTypes =>
      _parameterTypeByName.values;

  ParameterType<Object?>? lookupByTypeName(String typeName) {
    return _parameterTypeByName[typeName];
  }

  ParameterType<Object?>? lookupByRegexp(
    String parameterTypeRegexp,
    RegExp expressionRegexp,
    String text,
  ) {
    final parameterTypes = _parameterTypesByRegexp[parameterTypeRegexp];
    if (parameterTypes == null) {
      return null;
    }
    if (parameterTypes.length > 1 && !parameterTypes[0].preferForRegexpMatch) {
      // We don't do this check on insertion because we only want to restrict
      // ambiguity when we look up by Regexp. Users of CucumberExpression should
      // not be restricted.
      final generatedExpressions =
          CucumberExpressionGenerator(() => parameterTypes.cast())
              .generateExpressions(text);
      throw AmbiguousParameterTypeException.forRegExp(
        parameterTypeRegexp,
        expressionRegexp,
        parameterTypes,
        generatedExpressions,
      );
    }
    return parameterTypes[0];
  }

  @override
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
        parameterTypes.add(parameterType);
        parameterTypes.sort(ParameterType.compare);
      }
    }
  }
}
