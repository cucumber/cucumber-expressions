package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * Creates a {@link CucumberExpression} or {@link RegularExpression} from a {@link String}
 * using heuristics. This is particularly useful for languages that don't have a
 * literal syntax for regular expressions. In Java, a regular expression has to be represented as a String.
 *
 *  A string that starts with `^` and/or ends with `$` (or written in script style, i.e. starting with `/` 
 *  and ending with `/`) is considered a regular expression.
 *  Everything else is considered a Cucumber expression.
 */
@API(status = API.Status.STABLE)
public final class ExpressionFactory {

    private static final Pattern PARAMETER_PATTERN = Pattern.compile("((?:\\\\){0,2})\\{([^}]*)\\}");

    private final ParameterTypeRegistry parameterTypeRegistry;

    public ExpressionFactory(ParameterTypeRegistry parameterTypeRegistry) {
        this.parameterTypeRegistry = parameterTypeRegistry;
    }

    public Expression createExpression(String expressionString) {
        int length = expressionString.length();
        int lastCharIndex = 0;
        char firstChar = 0;
        char lastChar = 0;
        if (length > 0) {
            lastCharIndex = length - 1;
            firstChar = expressionString.charAt(0);
            lastChar = expressionString.charAt(lastCharIndex);
        }
        if (firstChar == '^' || lastChar == '$') {
            // java regexp => create from regexp
            return this.createRegularExpressionWithAnchors(expressionString);
        } else if (firstChar == '/' && lastChar == '/') {
            // script style regexp => create from regexp
            return new RegularExpression(Pattern.compile(expressionString.substring(1, lastCharIndex)), this.parameterTypeRegistry);
        } else {
            // otherwise create cucumber style expression
            return new CucumberExpression(expressionString, this.parameterTypeRegistry);
        }
    }

    private RegularExpression createRegularExpressionWithAnchors(String expressionString) {
        try {
            return new RegularExpression(Pattern.compile(expressionString), parameterTypeRegistry);
        } catch (PatternSyntaxException e) {
            if (PARAMETER_PATTERN.matcher(expressionString).find()) {
                throw new CucumberExpressionException("You cannot use anchors (^ or $) in Cucumber Expressions. Please remove them from " + expressionString, e);
            }
            throw e;
        }
    }
}
