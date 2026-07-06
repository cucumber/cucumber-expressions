import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

/// Something that can match text and produce a list of [Argument]s.
abstract class Expression {
  /// The original source string or pattern of this expression.
  String get source;

  /// Matches [text] against this expression.
  ///
  /// Returns the matched arguments, or `null` if the text does not match.
  List<Argument<Object?>>? match(String text);
}

/// Something that can have parameter types defined on it.
///
/// This is an interface implemented by registries and used as an abstraction
/// point, so it is intentionally an abstract class rather than a function.
// ignore: one_member_abstracts
abstract class DefinesParameterType {
  /// Registers [parameterType] so it can be referenced in expressions.
  void defineParameterType<T>(ParameterType<T> parameterType);
}
