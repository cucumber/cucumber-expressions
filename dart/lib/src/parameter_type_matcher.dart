import 'package:cucumber_expressions/src/parameter_type.dart';

final RegExp _wordBoundary = RegExp(r'\p{Z}|\p{P}|\p{S}', unicode: true);

/// Finds where one regular expression of a [ParameterType] matches a whole
/// word in a piece of text.
class ParameterTypeMatcher {
  /// Creates a matcher for [parameterType] using one of its regexp strings.
  ///
  /// The text is searched from the optional match position, which defaults
  /// to the start of the text.
  ParameterTypeMatcher(
    this.parameterType,
    this._regexpString,
    this._text, [
    this._matchPosition = 0,
  ]) : _match = RegExp(
         '($_regexpString)',
       ).firstMatch(_text.substring(_matchPosition));

  /// The parameter type this matcher looks for.
  final ParameterType<Object?> parameterType;
  final String _regexpString;
  final String _text;
  final int _matchPosition;
  final RegExpMatch? _match;

  /// A matcher for the first position at or after [newMatchPosition] where
  /// [find] is true.
  ///
  /// When there is no such position, the returned matcher's [find] is false.
  ParameterTypeMatcher advanceTo(int newMatchPosition) {
    for (
      var advancedPos = newMatchPosition;
      advancedPos < _text.length;
      advancedPos++
    ) {
      final matcher = ParameterTypeMatcher(
        parameterType,
        _regexpString,
        _text,
        advancedPos,
      );
      if (matcher.find) {
        return matcher;
      }
    }
    return ParameterTypeMatcher(
      parameterType,
      _regexpString,
      _text,
      _text.length,
    );
  }

  /// Whether there is a non-empty match covering a whole word.
  bool get find => _match != null && group != '' && fullWord;

  /// The index in the text where the match starts.
  ///
  /// Throws a [StateError] when there is no match.
  int get start {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return _matchPosition + match.start;
  }

  /// Whether the match starts and ends on word boundaries.
  bool get fullWord => matchStartWord && matchEndWord;

  /// Whether the match starts the text or follows a separator, punctuation,
  /// or symbol character.
  bool get matchStartWord =>
      start == 0 || _wordBoundary.hasMatch(_text[start - 1]);

  /// Whether the match ends the text or precedes a separator, punctuation,
  /// or symbol character.
  bool get matchEndWord {
    final nextCharacterIndex = start + group.length;
    return nextCharacterIndex == _text.length ||
        _wordBoundary.hasMatch(_text[nextCharacterIndex]);
  }

  /// The matched text.
  ///
  /// Throws a [StateError] when there is no match.
  String get group {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return match.group(0)!;
  }

  /// Orders matchers by match position, then by longest match first.
  ///
  /// Returns a negative number when [a] sorts before [b], a positive number
  /// when it sorts after, and zero otherwise.
  static int compare(ParameterTypeMatcher a, ParameterTypeMatcher b) {
    final posComparison = a.start - b.start;
    if (posComparison != 0) {
      return posComparison;
    }
    final lengthComparison = b.group.length - a.group.length;
    if (lengthComparison != 0) {
      return lengthComparison;
    }
    return 0;
  }
}
