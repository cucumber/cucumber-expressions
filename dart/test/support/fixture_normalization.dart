import 'package:yaml/yaml.dart';

Object? normalizeFixtureValue(Object? value) {
  if (value == null || value is num || value is String) return value;
  if (value is BigInt) return value.toString();
  if (value is Iterable) return value.map(normalizeFixtureValue).toList();
  return value.toString();
}

Object? normalizeExpectedFixtureValue(Object? value) {
  if (value == null || value is num || value is String) return value;
  if (value is YamlList || value is List) {
    return (value as Iterable).map(normalizeExpectedFixtureValue).toList();
  }
  return value.toString();
}
