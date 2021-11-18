namespace CucumberExpressions.Ast;

public static class AstExtensions
{
    public static string GetSymbol(this TokenType tokenType)
    {
        switch (tokenType)
        {
            case TokenType.BEGIN_OPTIONAL:
                return Token.BeginOptionalCharacter.ToString();
            case TokenType.END_OPTIONAL:
                return Token.EndOptionalCharacter.ToString();
            case TokenType.BEGIN_PARAMETER:
                return Token.BeginParameterCharacter.ToString();
            case TokenType.END_PARAMETER:
                return Token.EndParameterCharacter.ToString();
            case TokenType.ALTERNATION:
                return Token.AlternationCharacter.ToString();
        }

        return null;
    }

    public static string GetPurpose(this TokenType tokenType)
    {
        switch (tokenType)
        {
            case TokenType.BEGIN_OPTIONAL:
            case TokenType.END_OPTIONAL:
                return "optional text";
            case TokenType.BEGIN_PARAMETER:
            case TokenType.END_PARAMETER:
                return "a parameter";
            case TokenType.ALTERNATION:
                return "alternation";
        }

        return null;
    }
}