package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.Ast.Token;
import org.jspecify.annotations.Nullable;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.PrimitiveIterator.OfInt;

import static io.cucumber.cucumberexpressions.CucumberExpressionException.createCantEscape;
import static io.cucumber.cucumberexpressions.CucumberExpressionException.createTheEndOfLineCanNotBeEscaped;
import static java.util.Objects.requireNonNull;

final class CucumberExpressionTokenizer {

    List<Token> tokenize(String expression) {
        List<Token> tokens = new ArrayList<>();
        tokenizeImpl(expression).forEach(tokens::add);
        return tokens;
    }

    private Iterable<Token> tokenizeImpl(String expression) {
        return () -> new TokenIterator(expression);
    }

    private static class TokenIterator implements Iterator<Token> {

        private final String expression;
        private final OfInt codePoints;

        private StringBuilder buffer = new StringBuilder();
        private Token.@Nullable Type previousTokenType = null;
        private Token.@Nullable Type currentTokenType = Token.Type.START_OF_LINE;
        private boolean treatAsText;
        private int bufferStartIndex;
        private int escaped;

        TokenIterator(String expression) {
            this.expression = expression;
            this.codePoints = expression.codePoints().iterator();
        }

        private Token convertBufferToToken(Token.Type tokenType) {
            int escapeTokens = 0;
            if (tokenType == Token.Type.TEXT) {
                escapeTokens = escaped;
                escaped = 0;
            }
            int consumedIndex = bufferStartIndex + buffer.codePointCount(0, buffer.length()) + escapeTokens;
            Token t = new Token(buffer.toString(), tokenType, bufferStartIndex, consumedIndex);
            buffer = new StringBuilder();
            this.bufferStartIndex = consumedIndex;
            return t;
        }

        private void advanceTokenTypes() {
            previousTokenType = currentTokenType;
            currentTokenType = null;
        }

        private Token.Type tokenTypeOf(Integer token, boolean treatAsText) {
            if (!treatAsText) {
                return Token.typeOf(token);
            }
            if (Token.canEscape(token)) {
                return Token.Type.TEXT;
            }
            throw createCantEscape(expression, bufferStartIndex + buffer.codePointCount(0, buffer.length()) + escaped);
        }

        private boolean shouldContinueTokenType(Token.@Nullable Type previousTokenType,
                                                Token.@Nullable Type currentTokenType) {
            return currentTokenType == previousTokenType
                    && (currentTokenType == Token.Type.WHITE_SPACE || currentTokenType == Token.Type.TEXT);
        }

        @Override
        public boolean hasNext() {
            return previousTokenType != Token.Type.END_OF_LINE;
        }

        @Override
        public Token next() {
            if (!hasNext()) {
                throw new NoSuchElementException();
            }
            if (currentTokenType == Token.Type.START_OF_LINE) {
                Token token = convertBufferToToken(currentTokenType);
                advanceTokenTypes();
                return token;
            }

            while (codePoints.hasNext()) {
                int codePoint = codePoints.nextInt();
                if (!treatAsText && Token.isEscapeCharacter(codePoint)) {
                    escaped++;
                    treatAsText = true;
                    continue;
                }
                currentTokenType = tokenTypeOf(codePoint, treatAsText);
                treatAsText = false;

                if (previousTokenType == Token.Type.START_OF_LINE ||
                        shouldContinueTokenType(previousTokenType, currentTokenType)) {
                    advanceTokenTypes();
                    buffer.appendCodePoint(codePoint);
                } else {
                    Token t = convertBufferToToken(requireNonNull(previousTokenType));
                    advanceTokenTypes();
                    buffer.appendCodePoint(codePoint);
                    return t;
                }
            }

            if (!buffer.isEmpty()) {
                Token token = convertBufferToToken(requireNonNull(previousTokenType));
                advanceTokenTypes();
                return token;
            }

            currentTokenType = Token.Type.END_OF_LINE;
            if (treatAsText) {
                throw createTheEndOfLineCanNotBeEscaped(expression);
            }
            Token token = convertBufferToToken(currentTokenType);
            advanceTokenTypes();
            return token;
        }

    }

}
