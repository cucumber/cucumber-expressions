using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CucumberExpressions;

public class CucumberExpressionTokenizer
{
    public Ast.Token[] tokenize(string expression)
    {
        return TokenizeInternal(expression).ToArray();
    }
    public IEnumerable<Ast.Token> TokenizeInternal(string expression)
    {
        var iterator = new TokenIterator(expression);
        while (iterator.hasNext())
        {
            yield return iterator.next();
        }
    }

    private class TokenIterator
    {

        private string expression;
        private IEnumerator<char> codePoints;

        private StringBuilder buffer = new StringBuilder();
        private Ast.Token.Type previousTokenType = Ast.Token.Type.Unknown;
        private Ast.Token.Type currentTokenType = Ast.Token.Type.START_OF_LINE;
        private bool treatAsText;
        private int bufferStartIndex;
        private int escaped;

        public TokenIterator(string expression)
        {
            this.expression = expression;
            this.codePoints = expression.GetEnumerator();
        }

        private Ast.Token convertBufferToToken(Ast.Token.Type tokenType)
        {
            int escapeTokens = 0;
            if (tokenType == Ast.Token.Type.TEXT)
            {
                escapeTokens = escaped;
                escaped = 0;
            }
            int consumedIndex = bufferStartIndex + buffer.Length + escapeTokens;
            Ast.Token t = new Ast.Token(buffer.ToString(), tokenType, bufferStartIndex, consumedIndex);
            buffer = new StringBuilder();
            this.bufferStartIndex = consumedIndex;
            return t;
        }

        private void advanceTokenTypes()
        {
            previousTokenType = currentTokenType;
            currentTokenType = Ast.Token.Type.Unknown;
        }

        private Ast.Token.Type tokenTypeOf(char token, bool treatAsText)
        {
            if (!treatAsText)
            {
                return Ast.Token.typeOf(token);
            }
            if (Ast.Token.canEscape(token))
            {
                return Ast.Token.Type.TEXT;
            }
            throw CucumberExpressionException.createCantEscape(expression, bufferStartIndex + buffer.Length + escaped);
        }

        private bool shouldContinueTokenType(Ast.Token.Type? previousTokenType,
            Ast.Token.Type? currentTokenType)
        {
            return currentTokenType == previousTokenType
                    && (currentTokenType == Ast.Token.Type.WHITE_SPACE || currentTokenType == Ast.Token.Type.TEXT);
        }

        public bool hasNext()
        {
            return previousTokenType != Ast.Token.Type.END_OF_LINE;
        }

        public Ast.Token next()
        {
            if (!hasNext())
            {
                throw new InvalidOperationException("no such element");
            }
            if (currentTokenType == Ast.Token.Type.START_OF_LINE)
            {
                Ast.Token token = convertBufferToToken(currentTokenType);
                advanceTokenTypes();
                return token;
            }

            while (codePoints.MoveNext())
            {
                char codePoint = codePoints.Current;
                if (!treatAsText && Ast.Token.isEscapeCharacter(codePoint))
                {
                    escaped++;
                    treatAsText = true;
                    continue;
                }
                currentTokenType = tokenTypeOf(codePoint, treatAsText);
                treatAsText = false;

                if (previousTokenType == Ast.Token.Type.START_OF_LINE ||
                        shouldContinueTokenType(previousTokenType, currentTokenType))
                {
                    advanceTokenTypes();
                    buffer.Append(codePoint);
                }
                else
                {
                    Ast.Token t = convertBufferToToken(previousTokenType);
                    advanceTokenTypes();
                    buffer.Append(codePoint);
                    return t;
                }
            }

            if (buffer.Length > 0)
            {
                Ast.Token previousToken = convertBufferToToken(previousTokenType);
                advanceTokenTypes();
                return previousToken;
            }

            currentTokenType = Ast.Token.Type.END_OF_LINE;
            if (treatAsText)
            {
                throw CucumberExpressionException.createTheEndOfLineCanNotBeEscaped(expression);
            }
            Ast.Token currentToken = convertBufferToToken(currentTokenType);
            advanceTokenTypes();
            return currentToken;
        }

    }

}
