/// The character used to escape special characters in an expression.
const String escapeCharacter = r'\';

/// The character that separates alternatives in an alternation.
const String alternationCharacter = '/';

/// The character that begins a parameter type.
const String beginParameterCharacter = '{';

/// The character that ends a parameter type.
const String endParameterCharacter = '}';

/// The character that begins an optional.
const String beginOptionalCharacter = '(';

/// The character that ends an optional.
const String endOptionalCharacter = ')';

/// Returns the source symbol associated with [token], or an empty string when
/// the token has no dedicated symbol.
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

/// Returns a human readable description of the construct that [token]
/// introduces, or an empty string when the token has no such purpose.
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

/// Something that has a start and end position within the source expression.
abstract class Located {
  /// The zero-based index of the first character.
  int get start;

  /// The zero-based index one past the last character.
  int get end;
}

/// The kind of node in the abstract syntax tree.
enum NodeType {
  /// Literal text.
  text('TEXT_NODE'),

  /// An optional section, e.g. `(s)`.
  optional('OPTIONAL_NODE'),

  /// An alternation, e.g. `a/b`.
  alternation('ALTERNATION_NODE'),

  /// A single alternative within an alternation.
  alternative('ALTERNATIVE_NODE'),

  /// A parameter type, e.g. `{int}`.
  parameter('PARAMETER_NODE'),

  /// The root expression node.
  expression('EXPRESSION_NODE');

  const NodeType(this.value);

  /// The string representation of this node type.
  final String value;
}

/// A node in the parsed abstract syntax tree of a Cucumber Expression.
class Node implements Located {
  /// Creates a node of the given [type].
  ///
  /// Either [_nodes] or [_token] must be non-null.
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

  /// The child nodes, or `null` for leaf (token) nodes.
  List<Node>? get nodes => _nodes;

  /// The raw token text, or `null` for nodes that have children.
  String? get token => _token;

  /// The concatenated text of this node and all of its descendants.
  String text() {
    final localNodes = _nodes;
    if (localNodes != null && localNodes.isNotEmpty) {
      return localNodes.map((value) => value.text()).join();
    }
    return _token ?? '';
  }
}

/// The kind of token produced by the tokenizer.
enum TokenType {
  /// The synthetic token marking the start of the expression.
  startOfLine('START_OF_LINE'),

  /// The synthetic token marking the end of the expression.
  endOfLine('END_OF_LINE'),

  /// One or more whitespace characters.
  whiteSpace('WHITE_SPACE'),

  /// The `(` that begins an optional.
  beginOptional('BEGIN_OPTIONAL'),

  /// The `)` that ends an optional.
  endOptional('END_OPTIONAL'),

  /// The `{` that begins a parameter type.
  beginParameter('BEGIN_PARAMETER'),

  /// The `}` that ends a parameter type.
  endParameter('END_PARAMETER'),

  /// The `/` that separates alternatives.
  alternation('ALTERNATION'),

  /// Literal text.
  text('TEXT');

  const TokenType(this.value);

  /// The string representation of this token type.
  final String value;
}

/// A lexical token produced when tokenizing a Cucumber Expression.
class Token implements Located {
  /// Creates a token of the given [type] spanning [start] to [end].
  Token(this.type, this.text, this.start, this.end);

  /// The kind of this token.
  final TokenType type;

  /// The raw source text of this token.
  final String text;

  @override
  final int start;

  @override
  final int end;

  /// Whether [codePoint] is the escape character.
  static bool isEscapeCharacter(String codePoint) {
    return codePoint == escapeCharacter;
  }

  /// Whether [codePoint] may be escaped.
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

  /// Returns the [TokenType] that [codePoint] represents.
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
