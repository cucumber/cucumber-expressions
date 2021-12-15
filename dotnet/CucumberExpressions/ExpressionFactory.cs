using System;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

/// <summary>
/// Creates a {@link CucumberExpression} or {@link RegularExpression} from a {@link String}
/// using heuristics. 
/// </summary>
public class ExpressionFactory
{
    private static readonly Regex BeginAnchorRe = new("^\\^.*");
    private static readonly Regex EndAnchorRe = new(".*\\$$");
    private static readonly Regex ScriptStyleRegexpRe = new("^/(?<inner>.*)/$");
    private static readonly Regex ParameterPatternRe = new("((?:\\\\){0,2})\\{([^}]*)\\}");

    private readonly IParameterTypeRegistry _parameterTypeRegistry;

    public ExpressionFactory(IParameterTypeRegistry parameterTypeRegistry)
    {
        _parameterTypeRegistry = parameterTypeRegistry;
    }

    public IExpression CreateExpression(String expressionString)
    {
        if (BeginAnchorRe.IsMatch(expressionString) || EndAnchorRe.IsMatch(expressionString))
        {
            return createRegularExpressionWithAnchors(expressionString);
        }
        var scriptStyleRegexpMatch = ScriptStyleRegexpRe.Match(expressionString);
        if (scriptStyleRegexpMatch.Success)
        {
            return new RegularExpression(new(scriptStyleRegexpMatch.Groups["inner"].Value));
        }
        if (IsRegularExpression(expressionString))
            return createRegularExpressionWithAnchors(expressionString);
        return new CucumberExpression(expressionString, _parameterTypeRegistry);
    }

    protected virtual bool IsRegularExpression(string expressionString)
    {
        return false; // additional heuristics can be implemented in derived classes
    }

    private RegularExpression createRegularExpressionWithAnchors(string expressionString)
    {
        try
        {
            return new RegularExpression(new(expressionString));
        }
        catch (ArgumentException e)
        {
            if (ParameterPatternRe.IsMatch(expressionString))
            {
                throw new CucumberExpressionException("You cannot use anchors (^ or $) in Cucumber Expressions. Please remove them from " + expressionString, e);
            }
            throw new CucumberExpressionException($"Invalid regular expression: '{expressionString}'", e);
        }
    }
}
