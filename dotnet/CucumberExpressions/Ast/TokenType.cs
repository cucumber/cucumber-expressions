namespace CucumberExpressions.Ast;

public enum TokenType
{
    UNKNOWN,
    START_OF_LINE,
    END_OF_LINE,
    WHITE_SPACE,
    BEGIN_OPTIONAL,
    END_OPTIONAL,
    BEGIN_PARAMETER,
    END_PARAMETER,
    ALTERNATION,
    TEXT
}