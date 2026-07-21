import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_lookup.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/tree_regexp.dart';

/// An [Expression] backed by a plain [RegExp], resolving capture groups to
/// parameter types via a registry.
class RegularExpression implements Expression {
  /// Creates a regular expression matcher for [regexp] using
  /// [_parameterTypeRegistry] to resolve capture groups.
  RegularExpression(this.regexp, this._parameterTypeRegistry)
      : _treeRegexp = TreeRegexp(regexp);

  /// The underlying regular expression.
  final RegExp regexp;
  final ParameterTypeRegistry _parameterTypeRegistry;
  final TreeRegexp _treeRegexp;

  @override
  List<Argument<Object?>>? match(String text) {
    final group = _treeRegexp.match(text);
    if (group == null) {
      return null;
    }

    final parameterTypes =
        _treeRegexp.groupBuilder.children.map((groupBuilder) {
      final parameterTypeRegexp = groupBuilder.source;

      final parameterType = lookupParameterTypeByRegexp(
        _parameterTypeRegistry,
        parameterTypeRegexp,
        regexp,
        text,
      );
      return parameterType ??
          ParameterType<String?>(
            null,
            parameterTypeRegexp,
            'String',
            (s) => s.first,
            useForSnippets: false,
            preferForRegexpMatch: false,
          );
    }).toList();

    return buildArguments(group, parameterTypes);
  }

  @override
  String get source => regexp.pattern;
}
