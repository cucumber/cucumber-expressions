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
        private readonly IEnumerator<char> _codePoints;

        private StringBuilder _buffer = new();
        private TokenType _previousTokenType = TokenType.UNKNOWN;
        private TokenType _currentTokenType = TokenType.START_OF_LINE;
        private bool _treatAsText;
        private int _bufferStartIndex;
        private int _escaped;

        public TokenIterator(string expression)
        {
            _expression = expression;
            _codePoints = expression.GetEnumerator();
        }

        private Token ConvertBufferToToken(TokenType tokenType)
        {
            int escapeTokens = 0;
            if (tokenType == TokenType.TEXT)
            {
                escapeTokens = _escaped;
                _escaped = 0;
            }
            int consumedIndex = _bufferStartIndex + _buffer.Length + escapeTokens;
            Token t = new Token(_buffer.ToString(), tokenType, _bufferStartIndex, consumedIndex);
            _buffer = new StringBuilder();
            this._bufferStartIndex = consumedIndex;
            return t;
        }

        private void AdvanceTokenTypes()
        {
            _previousTokenType = _currentTokenType;
            _currentTokenType = TokenType.UNKNOWN;
        }

        private TokenType TokenTypeOf(char token, bool treatAsText)
        {
            if (!treatAsText)
            {
                return Token.TypeOf(token);
            }
            if (Token.CanEscape(token))
            {
                return TokenType.TEXT;
            }
            throw CucumberExpressionException.CreateCantEscape(_expression, _bufferStartIndex + _buffer.Length + _escaped);
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
                char codePoint = _codePoints.Current;
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
                    _buffer.Append(codePoint);
                }
                else
                {
                    Token t = ConvertBufferToToken(_previousTokenType);
                    AdvanceTokenTypes();
                    _buffer.Append(codePoint);
                    return t;
                }
            }

            if (_buffer.Length > 0)
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
