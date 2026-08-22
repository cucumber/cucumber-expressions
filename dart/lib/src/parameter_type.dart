import 'package:cucumber_expressions/src/errors.dart';

final RegExp _illegalParameterNamePattern = RegExp(r'([\[\]()$.|?*+])');
RegExp _unescapePattern() => RegExp(r'(\\([\[$.|?*+\]]))');

/// Transforms the captured group values of a parameter into a value of type
/// [T]. The list may contain `null` entries for unmatched optional groups.
typedef Transformer<T> = T Function(List<String?> groupValues);

/// Describes a `{name}` parameter type: how to match it and how to transform
/// the captured text into a value of type [T].
class ParameterType<T> {
  /// Creates a parameter type.
  ///
  /// [name] is the type name used in expressions, [regexps] is a single
  /// pattern or list of patterns (as [String] or [RegExp]), [type] is a human
  /// readable type description, and [transform] converts captured groups into
  /// a value of type [T].
  ParameterType(
    this.name,
    Object regexps,
    this.type,
    Transformer<T>? transform, {
    bool? useForSnippets,
    bool? preferForRegexpMatch,
  })  : useForSnippets = useForSnippets ?? true,
        preferForRegexpMatch = preferForRegexpMatch ?? false,
        regexpStrings = _stringArray(regexps),
        _transformFn = transform ?? ((List<String?> s) => s.first as T) {
    if (name != null) {
      _checkParameterTypeName(name!);
    }
  }

  /// The name of the type. May be `null` (e.g. for the anonymous type only the
  /// empty string is used as name; `null` means "no name").
  final String? name;

  /// A human readable representation of the produced type, used by the
  /// generator when building snippet parameter names. May be `null`.
  final String? type;

  /// Whether this type should be considered when generating snippets.
  final bool useForSnippets;

  /// Whether this type is preferred when matching by regular expression.
  final bool preferForRegexpMatch;

  /// The regular expression pattern strings this type matches.
  final List<String> regexpStrings;
  final Transformer<T> _transformFn;

  /// Transforms the captured [groupValues] into a value of type [T].
  T transform(List<String?> groupValues) {
    return _transformFn(groupValues);
  }
}

int compareParameterTypes(
  ParameterType<Object?> pt1,
  ParameterType<Object?> pt2,
) {
  if (pt1.preferForRegexpMatch && !pt2.preferForRegexpMatch) {
    return -1;
  }
  if (pt2.preferForRegexpMatch && !pt1.preferForRegexpMatch) {
    return 1;
  }
  return (pt1.name ?? '').compareTo(pt2.name ?? '');
}

void _checkParameterTypeName(String typeName) {
  if (!_isValidParameterTypeName(typeName)) {
    throw CucumberExpressionException(
      'Illegal character in parameter name {$typeName}. '
      r"Parameter names may not contain '{', '}', '(', ')', '\' or '/'",
    );
  }
}

bool _isValidParameterTypeName(String typeName) {
  final unescapedTypeName =
      typeName.replaceAllMapped(_unescapePattern(), (m) => m.group(2)!);
  return !_illegalParameterNamePattern.hasMatch(unescapedTypeName);
}

List<String> _stringArray(Object regexps) {
  final array = regexps is List<Object> ? regexps : <Object>[regexps];
  return array
      .map((r) => r is RegExp ? _regexpSource(r) : r as String)
      .toList();
}

String _regexpSource(RegExp regexp) {
  if (!regexp.isCaseSensitive) {
    throw CucumberExpressionException(
      "ParameterType Regexps can't use flag 'i'",
    );
  }
  if (regexp.isMultiLine) {
    throw CucumberExpressionException(
      "ParameterType Regexps can't use flag 'm'",
    );
  }
  return regexp.pattern;
}
