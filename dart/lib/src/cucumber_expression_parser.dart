import 'package:cucumber_expressions/src/ast.dart';
import 'package:cucumber_expressions/src/cucumber_expression_tokenizer.dart';
import 'package:cucumber_expressions/src/errors.dart';

class _Result {
  const _Result(this.consumed, this.ast);

  final int consumed;
  final List<Node> ast;
}

typedef _Parser = _Result Function(
  String expression,
  List<Token> tokens,
  int current,
);

_Result _parseText(String expression, List<Token> tokens, int current) {
  final token = tokens[current];
  switch (token.type) {
    case TokenType.whiteSpace:
    case TokenType.text:
    case TokenType.endParameter:
    case TokenType.endOptional:
      return _Result(1, [
        Node(NodeType.text, null, token.text, token.start, token.end),
      ]);
    case TokenType.alternation:
      throw createAlternationNotAllowedInOptional(expression, token);
    case TokenType.startOfLine:
    case TokenType.endOfLine:
    case TokenType.beginOptional:
    case TokenType.beginParameter:
      return const _Result(0, []);
  }
}

_Result _parseName(String expression, List<Token> tokens, int current) {
  final token = tokens[current];
  switch (token.type) {
    case TokenType.whiteSpace:
    case TokenType.text:
      return _Result(1, [
        Node(NodeType.text, null, token.text, token.start, token.end),
      ]);
    case TokenType.beginOptional:
    case TokenType.endOptional:
    case TokenType.beginParameter:
    case TokenType.endParameter:
    case TokenType.alternation:
      throw createInvalidParameterTypeNameInNode(token, expression);
    case TokenType.startOfLine:
    case TokenType.endOfLine:
      return const _Result(0, []);
  }
}

final _Parser _parseParameter = _parseBetween(
  NodeType.parameter,
  TokenType.beginParameter,
  TokenType.endParameter,
  [_parseName],
);

final List<_Parser> _optionalSubParsers = [];
final _Parser _parseOptional = _parseBetween(
  NodeType.optional,
  TokenType.beginOptional,
  TokenType.endOptional,
  _optionalSubParsers,
);

_Result _parseAlternativeSeparator(
  String expression,
  List<Token> tokens,
  int current,
) {
  if (!_lookingAt(tokens, current, TokenType.alternation)) {
    return const _Result(0, []);
  }
  final token = tokens[current];
  return _Result(1, [
    Node(NodeType.alternative, null, token.text, token.start, token.end),
  ]);
}

final List<_Parser> _alternativeParsers = [
  _parseAlternativeSeparator,
  _parseOptional,
  _parseParameter,
  _parseText,
];

_Result _parseAlternation(String expression, List<Token> tokens, int current) {
  final previous = current - 1;
  if (!_lookingAtAny(tokens, previous, [
    TokenType.startOfLine,
    TokenType.whiteSpace,
    TokenType.endParameter,
  ])) {
    return const _Result(0, []);
  }

  final result = _parseTokensUntil(
    expression,
    _alternativeParsers,
    tokens,
    current,
    [
      TokenType.whiteSpace,
      TokenType.endOfLine,
      TokenType.beginParameter,
    ],
  );
  final subCurrent = current + result.consumed;
  if (!result.ast.any((astNode) => astNode.type == NodeType.alternative)) {
    return const _Result(0, []);
  }

  final start = tokens[current].start;
  final end = tokens[subCurrent].start;
  return _Result(result.consumed, [
    Node(
      NodeType.alternation,
      _splitAlternatives(start, end, result.ast),
      null,
      start,
      end,
    ),
  ]);
}

final _Parser _parseCucumberExpression = _parseBetween(
  NodeType.expression,
  TokenType.startOfLine,
  TokenType.endOfLine,
  [_parseAlternation, _parseOptional, _parseParameter, _parseText],
);

class CucumberExpressionParser {
  CucumberExpressionParser() {
    if (_optionalSubParsers.isEmpty) {
      _optionalSubParsers.addAll([_parseOptional, _parseParameter, _parseText]);
    }
  }

  Node parse(String expression) {
    final tokenizer = CucumberExpressionTokenizer();
    final tokens = tokenizer.tokenize(expression);
    final result = _parseCucumberExpression(expression, tokens, 0);
    return result.ast[0];
  }
}

_Parser _parseBetween(
  NodeType type,
  TokenType beginToken,
  TokenType endToken,
  List<_Parser> parsers,
) {
  return (expression, tokens, current) {
    if (!_lookingAt(tokens, current, beginToken)) {
      return const _Result(0, []);
    }
    var subCurrent = current + 1;
    final result = _parseTokensUntil(
      expression,
      parsers,
      tokens,
      subCurrent,
      [endToken, TokenType.endOfLine],
    );
    subCurrent += result.consumed;

    if (!_lookingAt(tokens, subCurrent, endToken)) {
      throw createMissingEndToken(
        expression,
        beginToken,
        endToken,
        tokens[current],
      );
    }
    final start = tokens[current].start;
    final end = tokens[subCurrent].end;
    final consumed = subCurrent + 1 - current;
    final ast = [Node(type, result.ast, null, start, end)];
    return _Result(consumed, ast);
  };
}

_Result _parseToken(
  String expression,
  List<_Parser> parsers,
  List<Token> tokens,
  int startAt,
) {
  for (final parse in parsers) {
    final result = parse(expression, tokens, startAt);
    if (result.consumed != 0) {
      return result;
    }
  }
  throw StateError('No eligible parsers for $tokens');
}

_Result _parseTokensUntil(
  String expression,
  List<_Parser> parsers,
  List<Token> tokens,
  int startAt,
  List<TokenType> endTokens,
) {
  var current = startAt;
  final size = tokens.length;
  final ast = <Node>[];
  while (current < size) {
    if (_lookingAtAny(tokens, current, endTokens)) {
      break;
    }
    final result = _parseToken(expression, parsers, tokens, current);
    if (result.consumed == 0) {
      throw StateError('No eligible parsers for $tokens');
    }
    current += result.consumed;
    ast.addAll(result.ast);
  }
  return _Result(current - startAt, ast);
}

bool _lookingAtAny(List<Token> tokens, int at, List<TokenType> tokenTypes) {
  return tokenTypes.any((tokenType) => _lookingAt(tokens, at, tokenType));
}

bool _lookingAt(List<Token> tokens, int at, TokenType token) {
  if (at < 0) {
    return token == TokenType.startOfLine;
  }
  if (at >= tokens.length) {
    return token == TokenType.endOfLine;
  }
  return tokens[at].type == token;
}

List<Node> _splitAlternatives(int start, int end, List<Node> alternation) {
  final separators = <Node>[];
  final alternatives = <List<Node>>[];
  var alternative = <Node>[];
  for (final n in alternation) {
    if (NodeType.alternative == n.type) {
      separators.add(n);
      alternatives.add(alternative);
      alternative = <Node>[];
    } else {
      alternative.add(n);
    }
  }
  alternatives.add(alternative);
  return _createAlternativeNodes(start, end, separators, alternatives);
}

List<Node> _createAlternativeNodes(
  int start,
  int end,
  List<Node> separators,
  List<List<Node>> alternatives,
) {
  final nodes = <Node>[];

  for (var i = 0; i < alternatives.length; i++) {
    final n = alternatives[i];
    if (i == 0) {
      final rightSeparator = separators[i];
      nodes.add(
        Node(NodeType.alternative, n, null, start, rightSeparator.start),
      );
    } else if (i == alternatives.length - 1) {
      final leftSeparator = separators[i - 1];
      nodes.add(Node(NodeType.alternative, n, null, leftSeparator.end, end));
    } else {
      final leftSeparator = separators[i - 1];
      final rightSeparator = separators[i];
      nodes.add(
        Node(
          NodeType.alternative,
          n,
          null,
          leftSeparator.end,
          rightSeparator.start,
        ),
      );
    }
  }
  return nodes;
}
