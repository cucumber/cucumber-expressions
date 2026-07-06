import 'argument.dart';
import 'expression.dart';
import 'parameter_type.dart';
import 'parameter_type_registry.dart';
import 'tree_regexp.dart';

class RegularExpression implements Expression {
  RegularExpression(this.regexp, this._parameterTypeRegistry)
      : _treeRegexp = TreeRegexp(regexp);

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

      final parameterType = _parameterTypeRegistry.lookupByRegexp(
        parameterTypeRegexp,
        regexp,
        text,
      );
      return parameterType ??
          ParameterType<String?>(
            null,
            parameterTypeRegexp,
            'String',
            (List<String?> s) => s.first,
            useForSnippets: false,
            preferForRegexpMatch: false,
          );
    }).toList();

    return Argument.build(group, parameterTypes);
  }

  @override
  String get source => regexp.pattern;
}
