using System;
using System.Text;

namespace CucumberExpressions;

public class CucumberExpressionException : Exception {
    public CucumberExpressionException(string message) : base(message)
    {
    }

    public CucumberExpressionException(string message, Exception innerException) : base(message, innerException)
    {
    }

    static CucumberExpressionException createMissingEndToken(String expression, Ast.Token.Type beginToken, Ast.Token.Type endToken,
            Ast.Token current) {
        return new CucumberExpressionException(message(
                current.start,
                expression,
                pointAt(current),
                "The '" + beginToken.symbol() + "' does not have a matching '" + endToken.symbol() + "'",
                "If you did not intend to use " + beginToken.purpose() + " you can use '\\" + beginToken
                        .symbol() + "' to escape the " + beginToken.purpose()));
    }

    static CucumberExpressionException createAlternationNotAllowedInOptional(String expression, Ast.Token current) {
        return new CucumberExpressionException(message(
                current.start,
                expression,
                pointAt(current),
                "An alternation can not be used inside an optional",
                "You can use '\\/' to escape the the '/'"
        ));
    }

    public static CucumberExpressionException createTheEndOfLineCanNotBeEscaped(String expression) {
        int index = expression.Length - 1;
        return new CucumberExpressionException(message(
                index,
                expression,
                pointAt(index),
                "The end of line can not be escaped",
                "You can use '\\\\' to escape the the '\\'"
        ));
    }

    static CucumberExpressionException createAlternativeMayNotBeEmpty(Ast.Node node, String expression) {
        return new CucumberExpressionException(message(
                node.start,
                expression,
                pointAt(node),
                "Alternative may not be empty",
                "If you did not mean to use an alternative you can use '\\/' to escape the the '/'"));
    }

    static CucumberExpressionException createParameterIsNotAllowedInOptional(Ast.Node node, String expression) {
        return new CucumberExpressionException(message(
                node.start,
                expression,
                pointAt(node),
                "An optional may not contain a parameter type",
                "If you did not mean to use an parameter type you can use '\\{' to escape the the '{'"));
    }
    static CucumberExpressionException createOptionalIsNotAllowedInOptional(Ast.Node node, String expression) {
        return new CucumberExpressionException(message(
                node.start,
                expression,
                pointAt(node),
                "An optional may not contain an other optional",
                "If you did not mean to use an optional type you can use '\\(' to escape the the '('. For more complicated expressions consider using a regular expression instead."));
    }

    static CucumberExpressionException createOptionalMayNotBeEmpty(Ast.Node node, String expression) {
        return new CucumberExpressionException(message(
                node.start,
                expression,
                pointAt(node),
                "An optional must contain some text",
                "If you did not mean to use an optional you can use '\\(' to escape the the '('"));
    }

    static CucumberExpressionException createAlternativeMayNotExclusivelyContainOptionals(Ast.Node node,
            String expression) {
        return new CucumberExpressionException(message(
                node.start,
                expression,
                pointAt(node),
                "An alternative may not exclusively contain optionals",
                "If you did not mean to use an optional you can use '\\(' to escape the the '('"));
    }

    private static String thisCucumberExpressionHasAProblemAt(int index) {
        return "This Cucumber Expression has a problem at column " + (index + 1) + ":" + "\n";
    }

    public static CucumberExpressionException createCantEscape(String expression, int index) {
        return new CucumberExpressionException(message(
                index,
                expression,
                pointAt(index),
                "Only the characters '{', '}', '(', ')', '\\', '/' and whitespace can be escaped",
                "If you did mean to use an '\\' you can use '\\\\' to escape it"));
    }

    static CucumberExpressionException createInvalidParameterTypeName(String name) {
        return new CucumberExpressionException(
                "Illegal character in parameter name {" + name + "}. Parameter names may not contain '{', '}', '(', ')', '\\' or '/'");
    }

    /**
     * Not very clear, but this message has to be language independent
     * Other languages have dedicated syntax for writing down regular expressions
     * <p>
     * In java a regular expression has to start with {@code ^} and end with
     * {@code $} to be recognized as one by Cucumber.
     *
     * @see ExpressionFactory
     */
    static CucumberExpressionException createInvalidParameterTypeName(Ast.Token token, String expression) {
        return new CucumberExpressionException(message(
                token.start,
                expression,
                pointAt(token),
                "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'",
                "Did you mean to use a regular expression?"));
    }

    static String message(int index, String expression, String pointer, String problem,
            String solution) {
        return thisCucumberExpressionHasAProblemAt(index) +
                "\n" +
                expression + "\n" +
                pointer + "\n" +
                problem + ".\n" +
                solution;
    }

    static String pointAt(Ast.Located node) {
        StringBuilder pointer = new StringBuilder(pointAt(node.start));
        if (node.start + 1 < node.end) {
            for (int i = node.start + 1; i < node.end - 1; i++) {
                pointer.Append("-");
            }
            pointer.Append("^");
        }
        return pointer.ToString();
    }

    private static String pointAt(int index) {
        StringBuilder pointer = new StringBuilder();
        for (int i = 0; i < index; i++) {
            pointer.Append(" ");
        }
        pointer.Append("^");
        return pointer.ToString();
    }

}
