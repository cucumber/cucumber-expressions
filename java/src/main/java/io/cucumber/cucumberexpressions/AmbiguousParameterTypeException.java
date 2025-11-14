package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.util.ArrayList;
import java.util.List;
import java.util.SortedSet;
import java.util.regex.Pattern;

@API(status = API.Status.STABLE)
public final class AmbiguousParameterTypeException extends CucumberExpressionException {
    private final Pattern regexp;
    private final String parameterTypeRegexp;
    private final SortedSet<ParameterType<?>> parameterTypes;
    private final List<GeneratedExpression> generatedExpressions;

    AmbiguousParameterTypeException(String parameterTypeRegexp, Pattern expressionRegexp, SortedSet<ParameterType<?>> parameterTypes, List<GeneratedExpression> generatedExpressions) {
        super(String.format("""
                        Your Regular Expression /%s/
                        matches multiple parameter types with regexp /%s/:
                           %s
                        
                        I couldn't decide which one to use. You have two options:
                        
                        1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:
                           %s
                        
                        2) Make one of the parameter types preferential and continue to use a Regular Expression.
                        
                        """,
                expressionRegexp.pattern(),
                parameterTypeRegexp,
                parameterTypeNames(parameterTypes),
                expressions(generatedExpressions)
        ));
        this.regexp = expressionRegexp;
        this.parameterTypeRegexp = parameterTypeRegexp;
        this.parameterTypes = parameterTypes;
        this.generatedExpressions = generatedExpressions;
    }

    private static String parameterTypeNames(SortedSet<ParameterType<?>> parameterTypes) {

        List<String> parameterNames = new ArrayList<>();
        for (ParameterType<?> p : parameterTypes) {
            String s = "{" + p.getName() + "}";
            parameterNames.add(s);
        }
        return join(parameterNames);
    }

    private static String expressions(List<GeneratedExpression> generatedExpressions) {
        List<String> sources = new ArrayList<>();
        for (GeneratedExpression generatedExpression : generatedExpressions) {
            String source = generatedExpression.getSource();
            sources.add(source);
        }
        return join(sources);
    }

    private static String join(List<String> strings) {
        StringBuilder builder = new StringBuilder();
        boolean first = true;
        for (String element : strings) {
            if (first) {
                first = false;
            } else {
                builder.append("\n   ");
            }
            builder.append(element);
        }

        return builder.toString();
    }

    public Pattern getRegexp() {
        return regexp;
    }

    public String getParameterTypeRegexp() {
        return parameterTypeRegexp;
    }

    public SortedSet<ParameterType<?>> getParameterTypes() {
        return parameterTypes;
    }

    public List<GeneratedExpression> getGeneratedExpressions() {
        return generatedExpressions;
    }
}
