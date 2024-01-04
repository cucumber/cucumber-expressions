using System;

namespace CucumberExpressions.Ast;

public class Token : ILocated
{
    public const char EscapeCharacter = '\\';
    public const char AlternationCharacter = '/';
    public const char BeginParameterCharacter = '{';
    public const char EndParameterCharacter = '}';
    public const char BeginOptionalCharacter = '(';
    public const char EndOptionalCharacter = ')';

    public string Text { get; }
    public TokenType Type { get; }
    public int Start { get; }
    public int End { get; }

    public Token(string text, TokenType type, int start, int end)
    {
        Text = text ?? throw new ArgumentNullException(nameof(text));
        Type = type;
        Start = start;
        End = end;
    }

    public static bool CanEscape(char token)
    {
        if (char.IsWhiteSpace(token))
        {
            return true;
        }

        switch (token)
        {
            case EscapeCharacter:
            case AlternationCharacter:
            case BeginParameterCharacter:
            case EndParameterCharacter:
            case BeginOptionalCharacter:
            case EndOptionalCharacter:
                return true;
        }

        return false;
    }

    public static TokenType TypeOf(char token)
    {
        if (char.IsWhiteSpace(token))
        {
            return TokenType.WHITE_SPACE;
        }

        switch (token)
        {
            case AlternationCharacter:
                return TokenType.ALTERNATION;
            case BeginParameterCharacter:
                return TokenType.BEGIN_PARAMETER;
            case EndParameterCharacter:
                return TokenType.END_PARAMETER;
            case BeginOptionalCharacter:
                return TokenType.BEGIN_OPTIONAL;
            case EndOptionalCharacter:
                return TokenType.END_OPTIONAL;
        }

        return TokenType.TEXT;
    }

    public static bool IsEscapeCharacter(int token)
    {
        return token == EscapeCharacter;
    }

    public override string ToString()
    {
        return $"{{\"type\": \"{Type}\", \"start\": \"{Start}\", \"end\": \"{End}\", \"text\": \"{Text}\"}}";
    }

    #region Equality

    protected bool Equals(Token other)
    {
        return Text == other.Text && Type == other.Type && Start == other.Start && End == other.End;
    }

    public override bool Equals(object obj)
    {
        if (ReferenceEquals(null, obj)) return false;
        if (ReferenceEquals(this, obj)) return true;
        if (obj.GetType() != this.GetType()) return false;
        return Equals((Token)obj);
    }

    public override int GetHashCode()
    {
        unchecked
        {
            var hashCode = (Text != null ? Text.GetHashCode() : 0);
            hashCode = (hashCode * 397) ^ (int)Type;
            hashCode = (hashCode * 397) ^ Start;
            hashCode = (hashCode * 397) ^ End;
            return hashCode;
        }
    }

    #endregion
}