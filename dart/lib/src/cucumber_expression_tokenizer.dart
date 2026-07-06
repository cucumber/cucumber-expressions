import 'package:cucumber_expressions/src/ast.dart';
import 'package:cucumber_expressions/src/errors.dart';

/// Splits a Cucumber Expression string into a list of [Token]s.
class CucumberExpressionTokenizer {
  /// Tokenizes [expression] into a list of tokens, handling escaping.
  List<Token> tokenize(String expression) {
    final codePoints = expression.runes.map(String.fromCharCode).toList();
    final tokens = <Token>[];
    var buffer = <String>[];
    var previousTokenType = TokenType.startOfLine;
    var treatAsText = false;
    var escaped = 0;
    var bufferStartIndex = 0;

    Token convertBufferToToken(TokenType tokenType) {
      var escapeTokens = 0;
      if (tokenType == TokenType.text) {
        escapeTokens = escaped;
        escaped = 0;
      }

      final consumedIndex = bufferStartIndex + buffer.length + escapeTokens;
      final t =
          Token(tokenType, buffer.join(), bufferStartIndex, consumedIndex);
      buffer = <String>[];
      bufferStartIndex = consumedIndex;
      return t;
    }

    TokenType tokenTypeOf(String codePoint, {required bool treatAsText}) {
      if (!treatAsText) {
        return Token.typeOf(codePoint);
      }
      if (Token.canEscape(codePoint)) {
        return TokenType.text;
      }
      throw createCantEscaped(
        expression,
        bufferStartIndex + buffer.length + escaped,
      );
    }

    bool shouldCreateNewToken(
      TokenType previousTokenType,
      TokenType currentTokenType,
    ) {
      if (currentTokenType != previousTokenType) {
        return true;
      }
      return currentTokenType != TokenType.whiteSpace &&
          currentTokenType != TokenType.text;
    }

    if (codePoints.isEmpty) {
      tokens.add(Token(TokenType.startOfLine, '', 0, 0));
    }

    for (final codePoint in codePoints) {
      if (!treatAsText && Token.isEscapeCharacter(codePoint)) {
        escaped++;
        treatAsText = true;
        continue;
      }
      final currentTokenType = tokenTypeOf(codePoint, treatAsText: treatAsText);
      treatAsText = false;

      if (shouldCreateNewToken(previousTokenType, currentTokenType)) {
        final token = convertBufferToToken(previousTokenType);
        previousTokenType = currentTokenType;
        buffer.add(codePoint);
        tokens.add(token);
      } else {
        previousTokenType = currentTokenType;
        buffer.add(codePoint);
      }
    }

    if (buffer.isNotEmpty) {
      final token = convertBufferToToken(previousTokenType);
      tokens.add(token);
    }

    if (treatAsText) {
      throw createTheEndOfLineCanNotBeEscaped(expression);
    }

    tokens.add(
      Token(TokenType.endOfLine, '', codePoints.length, codePoints.length),
    );
    return tokens;
  }
}
