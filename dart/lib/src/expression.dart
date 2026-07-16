import 'package:cucumber_expressions/src/argument.dart';

/// Something that can match text and produce a list of [Argument]s.
abstract class Expression {
  /// The original source string or pattern of this expression.
  String get source;

  /// Matches [text] against this expression.
  ///
  /// Returns the matched arguments, or `null` if the text does not match.
  List<Argument<Object?>>? match(String text);
}
