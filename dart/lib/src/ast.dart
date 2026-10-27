/// The character that escapes the next character in an expression.
const String escapeCharacter = r'\';

/// The character that separates alternatives.
const String alternationCharacter = '/';

/// The character that opens a parameter.
const String beginParameterCharacter = '{';

/// The character that closes a parameter.
const String endParameterCharacter = '}';

/// The character that opens optional text.
const String beginOptionalCharacter = '(';

/// The character that closes optional text.
const String endOptionalCharacter = ')';

/// The source character for [token], or an empty string when [token] has no
/// single-character symbol.
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

/// A description of the construct [token] delimits, for use in error
/// messages, or an empty string when [token] does not delimit one.
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

/// Something that spans a range of code points in an expression.
abstract class Located {
  /// The index of the first code point.
  int get start;

  /// The index one past the last code point.
  int get end;
}

/// The kinds of [Node] in a parsed Cucumber Expression.
enum NodeType {
  /// Literal text.
  text('TEXT_NODE'),

  /// Optional text, written as `(text)`.
  optional('OPTIONAL_NODE'),

  /// A set of alternatives, written as `a/b`.
  alternation('ALTERNATION_NODE'),

  /// One alternative within an alternation, or a `/` separator while parsing.
  alternative('ALTERNATIVE_NODE'),

  /// A parameter, written as `{name}`.
  parameter('PARAMETER_NODE'),

  /// The root node of an expression.
  expression('EXPRESSION_NODE');

  const NodeType(this.value);

  /// The name used for this node type in the shared conformance fixtures.
  final String value;
}

/// A node in the abstract syntax tree of a Cucumber Expression.
class Node implements Located {
  /// Creates a node of [type] spanning [start] to [end].
  ///
  /// At least one of the child nodes or the token text must be non-null.
  /// Throws an [ArgumentError] when both are `null`.
  Node(this.type, this._nodes, this._token, this.start, this.end) {
    if (_nodes == null && _token == null) {
      throw ArgumentError('Either nodes or token must be defined');
    }
  }

  /// The kind of this node.
  final NodeType type;
  final List<Node>? _nodes;
  final String? _token;

  @override
  final int start;

  @override
  final int end;

  /// The child nodes, or `null` for a leaf node.
  List<Node>? get nodes => _nodes;

  /// The source text of a leaf node, or `null` for a node with children.
  String? get token => _token;

  /// The text of this node, concatenating the text of its children when it
  /// has any.
  String text() {
    final localNodes = _nodes;
    if (localNodes != null && localNodes.isNotEmpty) {
      return localNodes.map((value) => value.text()).join();
    }
    return _token ?? '';
  }
}

/// The kinds of [Token] produced when tokenizing a Cucumber Expression.
enum TokenType {
  /// The start of the expression.
  startOfLine('START_OF_LINE'),

  /// The end of the expression.
  endOfLine('END_OF_LINE'),

  /// A run of whitespace.
  whiteSpace('WHITE_SPACE'),

  /// The `(` that opens optional text.
  beginOptional('BEGIN_OPTIONAL'),

  /// The `)` that closes optional text.
  endOptional('END_OPTIONAL'),

  /// The `{` that opens a parameter.
  beginParameter('BEGIN_PARAMETER'),

  /// The `}` that closes a parameter.
  endParameter('END_PARAMETER'),

  /// The `/` that separates alternatives.
  alternation('ALTERNATION'),

  /// A run of literal text.
  text('TEXT');

  const TokenType(this.value);

  /// The name used for this token type in the shared conformance fixtures.
  final String value;
}

/// A token produced when tokenizing a Cucumber Expression.
class Token implements Located {
  /// Creates a token of [type] with [text] spanning [start] to [end].
  Token(this.type, this.text, this.start, this.end);

  /// The kind of this token.
  final TokenType type;

  /// The token text, with escape characters removed.
  final String text;

  @override
  final int start;

  @override
  final int end;

  /// Whether [codePoint] is the [escapeCharacter].
  static bool isEscapeCharacter(String codePoint) {
    return codePoint == escapeCharacter;
  }

  /// Whether [codePoint] may follow the [escapeCharacter].
  ///
  /// Only whitespace and the characters with special meaning in an
  /// expression can be escaped.
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

  /// The [TokenType] that unescaped [codePoint] belongs to.
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
