import 'expression.dart';
import 'parameter_type.dart';

const List<String> _integerRegexps = [r'-?\d+', r'\d+'];
const String _floatRegexp =
    r'(?=.*\d.*)[-+]?\d*(?:\.(?=\d.*))?\d*(?:\d+[E][+-]?\d+)?';
const String _wordRegexp = r'[^\s]+';
final String _stringRegexp = '"([^"\\\\]*(\\\\.[^"\\\\]*)*)"'
    "|'([^'\\\\]*(\\\\.[^'\\\\]*)*)'";
const String _anonymousRegexp = r'.*';

int? _toInt(List<String?> s) {
  final v = s.first;
  return v == null ? null : int.parse(v);
}

double? _toDouble(List<String?> s) {
  final v = s.first;
  return v == null ? null : double.parse(v);
}

BigInt? _toBigInt(List<String?> s) {
  final v = s.first;
  return v == null ? null : BigInt.parse(v);
}

String? _toStringValue(List<String?> s) => s.first;

void defineDefaultParameterTypes(DefinesParameterType registry) {
  registry.defineParameterType(
    ParameterType<int?>(
      'int',
      _integerRegexps,
      'int',
      _toInt,
      useForSnippets: true,
      preferForRegexpMatch: true,
      builtin: true,
    ),
  );
  registry.defineParameterType(
    ParameterType<double?>(
      'float',
      _floatRegexp,
      'double',
      _toDouble,
      useForSnippets: true,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );
  registry.defineParameterType(
    ParameterType<String?>(
      'word',
      _wordRegexp,
      'String',
      _toStringValue,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );
  registry.defineParameterType(
    ParameterType<String?>(
      'string',
      _stringRegexp,
      'String',
      (List<String?> groups) {
        final s1 = groups.isNotEmpty ? groups[0] : null;
        final s2 = groups.length > 1 ? groups[1] : null;
        return (s1 ?? s2 ?? '').replaceAll(r'\"', '"').replaceAll(r"\'", "'");
      },
      useForSnippets: true,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );
  registry.defineParameterType(
    ParameterType<String?>(
      '',
      _anonymousRegexp,
      'String',
      _toStringValue,
      useForSnippets: false,
      preferForRegexpMatch: true,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<double?>(
      'double',
      _floatRegexp,
      'double',
      _toDouble,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<String?>(
      'bigdecimal',
      _floatRegexp,
      'String',
      _toStringValue,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<int?>(
      'byte',
      _integerRegexps,
      'int',
      _toInt,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<int?>(
      'short',
      _integerRegexps,
      'int',
      _toInt,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<int?>(
      'long',
      _integerRegexps,
      'int',
      _toInt,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );

  registry.defineParameterType(
    ParameterType<BigInt?>(
      'biginteger',
      _integerRegexps,
      'BigInt',
      _toBigInt,
      useForSnippets: false,
      preferForRegexpMatch: false,
      builtin: true,
    ),
  );
}
