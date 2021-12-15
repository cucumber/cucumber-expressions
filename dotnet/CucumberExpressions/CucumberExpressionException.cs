using System;
using System.Text;
using CucumberExpressions.Ast;

namespace CucumberExpressions;

public class CucumberExpressionException : Exception {
    public CucumberExpressionException(string message) : base(message)
    {
    }

    public CucumberExpressionException(string message, Exception innerException) : base(message, innerException)
    {
    }

    internal static CucumberExpressionException CreateMissingEndToken(string expression, TokenType beginToken, TokenType endToken,
            Token current) {
        return new CucumberExpressionException(GetMessage(
                current.Start,
                expression,
                PointAt(current),
                "The '" + beginToken.GetSymbol() + "' does not have a matching '" + endToken.GetSymbol() + "'",
                "If you did not intend to use " + beginToken.GetPurpose() + " you can use '\\" + beginToken
                        .GetSymbol() + "' to escape the " + beginToken.GetPurpose()));
    }

    internal static CucumberExpressionException CreateAlternationNotAllowedInOptional(string expression, Token current) {
        return new CucumberExpressionException(GetMessage(
                current.Start,
                expression,
                PointAt(current),
                "An alternation can not be used inside an optional",
                "You can use '\\/' to escape the the '/'"
        ));
    }

    internal static CucumberExpressionException CreateTheEndOfLineCanNotBeEscaped(string expression) {
        int index = expression.Length - 1;
        return new CucumberExpressionException(GetMessage(
                index,
                expression,
                PointAt(index),
                "The end of line can not be escaped",
                "You can use '\\\\' to escape the the '\\'"
        ));
    }

    internal static CucumberExpressionException CreateAlternativeMayNotBeEmpty(Node node, string expression) {
        return new CucumberExpressionException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "Alternative may not be empty",
                "If you did not mean to use an alternative you can use '\\/' to escape the the '/'"));
    }

    internal static CucumberExpressionException CreateParameterIsNotAllowedInOptional(Node node, string expression) {
        return new CucumberExpressionException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "An optional may not contain a parameter type",
                "If you did not mean to use an parameter type you can use '\\{' to escape the the '{'"));
    }
    internal static CucumberExpressionException CreateOptionalIsNotAllowedInOptional(Node node, string expression) {
        return new CucumberExpressionException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "An optional may not contain an other optional",
                "If you did not mean to use an optional type you can use '\\(' to escape the the '('. For more complicated expressions consider using a regular expression instead."));
    }

    internal static CucumberExpressionException CreateOptionalMayNotBeEmpty(Node node, string expression) {
        return new CucumberExpressionException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "An optional must contain some text",
                "If you did not mean to use an optional you can use '\\(' to escape the the '('"));
    }

    internal static CucumberExpressionException CreateAlternativeMayNotExclusivelyContainOptionals(Node node,
            string expression) {
        return new CucumberExpressionException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "An alternative may not exclusively contain optionals",
                "If you did not mean to use an optional you can use '\\(' to escape the the '('"));
    }

    private static string ThisCucumberExpressionHasAProblemAt(int index) {
        return "This Cucumber Expression has a problem at column " + (index + 1) + ":" + "\n";
    }

    internal static CucumberExpressionException CreateCantEscape(string expression, int index) {
        return new CucumberExpressionException(GetMessage(
                index,
                expression,
                PointAt(index),
                "Only the characters '{', '}', '(', ')', '\\', '/' and whitespace can be escaped",
                "If you did mean to use an '\\' you can use '\\\\' to escape it"));
    }

    public static CucumberExpressionException CreateInvalidParameterTypeName(string name) {
        return new CucumberExpressionException(
                "Illegal character in parameter name {" + name + "}. Parameter names may not contain '{', '}', '(', ')', '\\' or '/'");
    }

    /**
     * Not very clear, but this message has to be language independent
     * Other languages have dedicated syntax for writing down regular expressions
     * 
     * In java a regular expression has to start with {@code ^} and end with
     * {@code $} to be recognized as one by Cucumber.
     *
     * @see ExpressionFactory
     */
    internal static CucumberExpressionException CreateInvalidParameterTypeName(Token token, string expression) {
        return new CucumberExpressionException(GetMessage(
                token.Start,
                expression,
                PointAt(token),
                "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'",
                "Did you mean to use a regular expression?"));
    }

    protected static string GetMessage(int index, string expression, string pointer, string problem,
            string solution) {
        return ThisCucumberExpressionHasAProblemAt(index) +
                "\n" +
                expression + "\n" +
                pointer + "\n" +
                problem + ".\n" +
                solution;
    }

    protected static string PointAt(ILocated node) {
        StringBuilder pointer = new StringBuilder(PointAt(node.Start));
        if (node.Start + 1 < node.End) {
            for (int i = node.Start + 1; i < node.End - 1; i++) {
                pointer.Append("-");
            }
            pointer.Append("^");
        }
        return pointer.ToString();
    }

    private static string PointAt(int index) {
        StringBuilder pointer = new StringBuilder();
        for (int i = 0; i < index; i++) {
            pointer.Append(" ");
        }
        pointer.Append("^");
        return pointer.ToString();
    }

}
