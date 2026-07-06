import 'package:cucumber_expressions/src/parameter_type.dart';

final RegExp _wordBoundary = RegExp(r'\p{Z}|\p{P}|\p{S}', unicode: true);

/// Matches a single parameter type's regular expression against text, used by
/// the expression generator to find candidate parameters.
class ParameterTypeMatcher {
  /// Creates a matcher for [parameterType] using [_regexpString] against
  /// [_text], starting at [_matchPosition].
  ParameterTypeMatcher(
    this.parameterType,
    this._regexpString,
    this._text, [
    this._matchPosition = 0,
  ]) : _match = RegExp('($_regexpString)').firstMatch(
          _text.substring(_matchPosition),
        );

  /// The parameter type this matcher represents.
  final ParameterType<Object?> parameterType;
  final String _regexpString;
  final String _text;
  final int _matchPosition;
  final RegExpMatch? _match;

  /// Returns a matcher advanced to the next match at or after
  /// [newMatchPosition].
  ParameterTypeMatcher advanceTo(int newMatchPosition) {
    for (var advancedPos = newMatchPosition;
        advancedPos < _text.length;
        advancedPos++) {
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

  /// Whether a non-empty, full-word match was found.
  bool get find => _match != null && group != '' && fullWord;

  /// The start index of the match within the text.
  int get start {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return _matchPosition + match.start;
  }

  /// Whether the match starts and ends on word boundaries.
  bool get fullWord => matchStartWord && matchEndWord;

  /// Whether the match starts on a word boundary.
  bool get matchStartWord =>
      start == 0 || _wordBoundary.hasMatch(_text[start - 1]);

  /// Whether the match ends on a word boundary.
  bool get matchEndWord {
    final nextCharacterIndex = start + group.length;
    return nextCharacterIndex == _text.length ||
        _wordBoundary.hasMatch(_text[nextCharacterIndex]);
  }

  /// The matched substring.
  String get group {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return match.group(0)!;
  }

  /// Orders matchers by start position, then by descending match length.
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
