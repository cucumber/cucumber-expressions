const String escapeCharacter = r'\';

const String alternationCharacter = '/';

const String beginParameterCharacter = '{';

const String endParameterCharacter = '}';

const String beginOptionalCharacter = '(';

const String endOptionalCharacter = ')';

String symbolOf(TokenType token) {
  switch (token) {
    case TokenType.beginOptional:
      return beginOptionalCharacter;
    case TokenType.endOptional:
      return endOptionalCharacter;
    case TokenType.beginParameter:
      return beginParameterCharacter;
    case TokenType.endParameter:
      return endParameterCharacter;
    case TokenType.alternation:
      return alternationCharacter;
    case TokenType.startOfLine:
    case TokenType.endOfLine:
    case TokenType.whiteSpace:
    case TokenType.text:
      return '';
  }
}

String purposeOf(TokenType token) {
  switch (token) {
    case TokenType.beginOptional:
    case TokenType.endOptional:
      return 'optional text';
    case TokenType.beginParameter:
    case TokenType.endParameter:
      return 'a parameter';
    case TokenType.alternation:
      return 'alternation';
    case TokenType.startOfLine:
    case TokenType.endOfLine:
    case TokenType.whiteSpace:
    case TokenType.text:
      return '';
  }
}

abstract class Located {
  int get start;

  int get end;
}

enum NodeType {
  text('TEXT_NODE'),

  optional('OPTIONAL_NODE'),

  alternation('ALTERNATION_NODE'),

  alternative('ALTERNATIVE_NODE'),

  parameter('PARAMETER_NODE'),

  expression('EXPRESSION_NODE');

  const NodeType(this.value);

  final String value;
}

class Node implements Located {
  Node(this.type, this._nodes, this._token, this.start, this.end) {
    if (_nodes == null && _token == null) {
      throw ArgumentError('Either nodes or token must be defined');
    }
  }

  final NodeType type;
  final List<Node>? _nodes;
  final String? _token;

  @override
  final int start;

  @override
  final int end;

  List<Node>? get nodes => _nodes;

  String? get token => _token;

  String text() {
    final localNodes = _nodes;
    if (localNodes != null && localNodes.isNotEmpty) {
      return localNodes.map((value) => value.text()).join();
    }
    return _token ?? '';
  }
}

enum TokenType {
  startOfLine('START_OF_LINE'),

  endOfLine('END_OF_LINE'),

  whiteSpace('WHITE_SPACE'),

  beginOptional('BEGIN_OPTIONAL'),

  endOptional('END_OPTIONAL'),

  beginParameter('BEGIN_PARAMETER'),

  endParameter('END_PARAMETER'),

  alternation('ALTERNATION'),

  text('TEXT');

  const TokenType(this.value);

  final String value;
}

class Token implements Located {
  Token(this.type, this.text, this.start, this.end);

  final TokenType type;

  final String text;

  @override
  final int start;

  @override
  final int end;

  static bool isEscapeCharacter(String codePoint) {
    return codePoint == escapeCharacter;
  }

  static bool canEscape(String codePoint) {
    if (_isWhitespace(codePoint)) {
      return true;
    }
    switch (codePoint) {
      case escapeCharacter:
      case alternationCharacter:
      case beginParameterCharacter:
      case endParameterCharacter:
      case beginOptionalCharacter:
      case endOptionalCharacter:
        return true;
    }
    return false;
  }

  static TokenType typeOf(String codePoint) {
    if (_isWhitespace(codePoint)) {
      return TokenType.whiteSpace;
    }
    switch (codePoint) {
      case alternationCharacter:
        return TokenType.alternation;
      case beginParameterCharacter:
        return TokenType.beginParameter;
      case endParameterCharacter:
        return TokenType.endParameter;
      case beginOptionalCharacter:
        return TokenType.beginOptional;
      case endOptionalCharacter:
        return TokenType.endOptional;
    }
    return TokenType.text;
  }

  static final RegExp _whitespacePattern = RegExp(r'\s', unicode: true);

  static bool _isWhitespace(String codePoint) {
    return _whitespacePattern.hasMatch(codePoint);
  }
}
