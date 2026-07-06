import 'parameter_type.dart';

final RegExp _wordBoundary = RegExp(r'\p{Z}|\p{P}|\p{S}', unicode: true);

class ParameterTypeMatcher {
  ParameterTypeMatcher(
    this.parameterType,
    this._regexpString,
    this._text, [
    this._matchPosition = 0,
  ]) : _match = RegExp('($_regexpString)').firstMatch(
          _text.substring(_matchPosition),
        );

  final ParameterType<Object?> parameterType;
  final String _regexpString;
  final String _text;
  final int _matchPosition;
  final RegExpMatch? _match;

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

  bool get find => _match != null && group != '' && fullWord;

  int get start {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return _matchPosition + match.start;
  }

  bool get fullWord => matchStartWord && matchEndWord;

  bool get matchStartWord =>
      start == 0 || _wordBoundary.hasMatch(_text[start - 1]);

  bool get matchEndWord {
    final nextCharacterIndex = start + group.length;
    return nextCharacterIndex == _text.length ||
        _wordBoundary.hasMatch(_text[nextCharacterIndex]);
  }

  String get group {
    final match = _match;
    if (match == null) {
      throw StateError('No match');
    }
    return match.group(0)!;
  }

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
