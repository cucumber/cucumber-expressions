using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

/// <summary>
/// Creates a {@link CucumberExpression} or {@link RegularExpression} from a {@link String}
/// using heuristics. 
/// </summary>
public class ExpressionFactory {

    private static readonly Regex BEGIN_ANCHOR = new("^\\^.*");
    private static readonly Regex END_ANCHOR = new(".*\\$$");
    private static readonly Regex SCRIPT_STYLE_REGEXP = new("^/(?<inner>.*)/$");
    private static readonly Regex PARAMETER_PATTERN = new("((?:\\\\){0,2})\\{([^}]*)\\}");

    private readonly IParameterTypeRegistry parameterTypeRegistry;

    public ExpressionFactory(IParameterTypeRegistry parameterTypeRegistry) {
        this.parameterTypeRegistry = parameterTypeRegistry;
    }

    public Expression createExpression(String expressionString) {
        if (BEGIN_ANCHOR.IsMatch(expressionString) || END_ANCHOR.IsMatch(expressionString)) {
            return createRegularExpressionWithAnchors(expressionString);
        }
        var m = SCRIPT_STYLE_REGEXP.Match(expressionString);
        if (m.Success) {
            return new RegularExpression(new(m.Groups["inner"].Value), parameterTypeRegistry);
        }
        if (IsRegularExpression(expressionString))
            return createRegularExpressionWithAnchors(expressionString);
        return new CucumberExpression(expressionString, parameterTypeRegistry);
    }

    protected virtual bool IsRegularExpression(string expressionString)
    {
        return false; // additional heuristics can be implemented in derived classes
    }

    private RegularExpression createRegularExpressionWithAnchors(String expressionString) {
        try {
            return new RegularExpression(new(expressionString), parameterTypeRegistry);
        } catch (ArgumentException e) {
            if (PARAMETER_PATTERN.IsMatch(expressionString)) {
                throw new CucumberExpressionException("You cannot use anchors (^ or $) in Cucumber Expressions. Please remove them from " + expressionString, e);
            }
            throw new CucumberExpressionException($"Invalid regular expression: '{expressionString}'", e);
        }
    }
}
