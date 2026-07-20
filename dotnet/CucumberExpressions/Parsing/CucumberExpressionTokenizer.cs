using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using CucumberExpressions.Ast;

namespace CucumberExpressions.Parsing;

public class CucumberExpressionTokenizer
{
    public Token[] Tokenize(string expression)
    {
        return TokenizeInternal(expression).ToArray();
    }
    public IEnumerable<Token> TokenizeInternal(string expression)
    {
        var iterator = new TokenIterator(expression);
        while (iterator.HasNext())
        {
            yield return iterator.Next();
        }
    }

    private class TokenIterator
    {
        private readonly string _expression;
        private readonly IEnumerator<int> _codePoints;

        private StringBuilder _buffer = new();
        private int _bufferCodePointCount;
        private TokenType _previousTokenType = TokenType.UNKNOWN;
        private TokenType _currentTokenType = TokenType.START_OF_LINE;
        private bool _treatAsText;
        private int _bufferStartIndex;
        private int _escaped;

        public TokenIterator(string expression)
        {
            _expression = expression;
            _codePoints = CodePointsOf(expression).GetEnumerator();
        }

        private Token ConvertBufferToToken(TokenType tokenType)
        {
            int escapeTokens = 0;
            if (tokenType == TokenType.TEXT)
            {
                escapeTokens = _escaped;
                _escaped = 0;
            }
            int consumedIndex = _bufferStartIndex + _bufferCodePointCount + escapeTokens;
            Token t = new Token(_buffer.ToString(), tokenType, _bufferStartIndex, consumedIndex);
            _buffer = new StringBuilder();
            _bufferCodePointCount = 0;
            this._bufferStartIndex = consumedIndex;
            return t;
        }

        private void AppendCodePoint(int codePoint)
        {
            _buffer.Append(char.ConvertFromUtf32(codePoint));
            _bufferCodePointCount++;
        }

        private void AdvanceTokenTypes()
        {
            _previousTokenType = _currentTokenType;
            _currentTokenType = TokenType.UNKNOWN;
        }

        private TokenType TokenTypeOf(int token, bool treatAsText)
        {
            if (!treatAsText)
            {
                return Token.TypeOf(token);
            }
            if (Token.CanEscape(token))
            {
                return TokenType.TEXT;
            }
            throw CucumberExpressionException.CreateCantEscape(_expression, _bufferStartIndex + _bufferCodePointCount + _escaped);
        }

        // Offsets are codepoint offsets, so the expression has to be walked a
        // codepoint at a time. A plain foreach over a string yields UTF-16 code
        // units, which counts anything outside the BMP twice. netstandard2.0
        // has no EnumerateRunes, hence the manual surrogate pairing.
        private static IEnumerable<int> CodePointsOf(string expression)
        {
            for (int i = 0; i < expression.Length; i++)
            {
                if (char.IsHighSurrogate(expression[i])
                    && i + 1 < expression.Length
                    && char.IsLowSurrogate(expression[i + 1]))
                {
                    yield return char.ConvertToUtf32(expression[i], expression[i + 1]);
                    i++;
                }
                else
                {
                    yield return expression[i];
                }
            }
        }

        private bool ShouldContinueTokenType(TokenType? previousTokenType, TokenType? currentTokenType)
        {
            return currentTokenType == previousTokenType
                    && (currentTokenType == TokenType.WHITE_SPACE || currentTokenType == TokenType.TEXT);
        }

        public bool HasNext()
        {
            return _previousTokenType != TokenType.END_OF_LINE;
        }

        public Token Next()
        {
            if (!HasNext())
            {
                throw new InvalidOperationException("no such element");
            }
            if (_currentTokenType == TokenType.START_OF_LINE)
            {
                Token token = ConvertBufferToToken(_currentTokenType);
                AdvanceTokenTypes();
                return token;
            }

            while (_codePoints.MoveNext())
            {
                int codePoint = _codePoints.Current;
                if (!_treatAsText && Token.IsEscapeCharacter(codePoint))
                {
                    _escaped++;
                    _treatAsText = true;
                    continue;
                }
                _currentTokenType = TokenTypeOf(codePoint, _treatAsText);
                _treatAsText = false;

                if (_previousTokenType == TokenType.START_OF_LINE ||
                        ShouldContinueTokenType(_previousTokenType, _currentTokenType))
                {
                    AdvanceTokenTypes();
                    AppendCodePoint(codePoint);
                }
                else
                {
                    Token t = ConvertBufferToToken(_previousTokenType);
                    AdvanceTokenTypes();
                    AppendCodePoint(codePoint);
                    return t;
                }
            }

            if (_bufferCodePointCount > 0)
            {
                Token previousToken = ConvertBufferToToken(_previousTokenType);
                AdvanceTokenTypes();
                return previousToken;
            }

            _currentTokenType = TokenType.END_OF_LINE;
            if (_treatAsText)
            {
                throw CucumberExpressionException.CreateTheEndOfLineCanNotBeEscaped(_expression);
            }
            Token currentToken = ConvertBufferToToken(_currentTokenType);
            AdvanceTokenTypes();
            return currentToken;
        }

    }

}
