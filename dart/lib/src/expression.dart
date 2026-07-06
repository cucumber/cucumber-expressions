import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

/// Something that can match text and produce a list of [Argument]s.
abstract class Expression {
  String get source;

  List<Argument<Object?>>? match(String text);
}

/// Something that can have parameter types defined on it.
abstract class DefinesParameterType {
  void defineParameterType<T>(ParameterType<T> parameterType);
}
