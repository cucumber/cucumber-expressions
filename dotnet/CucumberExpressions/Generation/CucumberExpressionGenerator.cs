using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions.Generation;

public class CucumberExpressionGenerator
{
    private readonly IParameterTypeRegistry _parameterTypeRegistry;

    public CucumberExpressionGenerator(IParameterTypeRegistry parameterTypeRegistry)
    {
        _parameterTypeRegistry = parameterTypeRegistry;
    }

    public GeneratedExpression[] GenerateExpressions(string text)
    {
        var parameterTypeCombinations = new List<List<IParameterType>>();
        var parameterTypeMatchers = CreateParameterTypeMatchers(text);
        StringBuilder expressionTemplate = new StringBuilder();
        int pos = 0;
        int paramCount = 0;
        while (true)
        {
            var matchingParameterTypeMatchers = new List<ParameterTypeMatcher>();

            foreach (var parameterTypeMatcher in parameterTypeMatchers)
            {
                if (parameterTypeMatcher.AdvanceToAndFind(pos))
                {
                    matchingParameterTypeMatchers.Add(parameterTypeMatcher);
                }
            }

            if (matchingParameterTypeMatchers.Any())
            {
                matchingParameterTypeMatchers.Sort();

                // Find all the best parameter type matchers, they are all candidates.
                var bestParameterTypeMatcher = matchingParameterTypeMatchers[0];
                var bestParameterTypeMatchers = new List<ParameterTypeMatcher>();
                foreach (var m in matchingParameterTypeMatchers)
                {
                    if (m.CompareTo(bestParameterTypeMatcher) == 0)
                    {
                        bestParameterTypeMatchers.Add(m);
                    }
                }

                // Build a list of parameter types without duplicates. The reason there
                // might be duplicates is that some parameter types have more than one regexp,
                // which means multiple ParameterTypeMatcher objects will have a reference to the
                // same ParameterType.
                // We're sorting the list so preferential parameter types are listed first.
                // Users are most likely to want these, so they should be listed at the top.
                var set = new HashSet<IParameterType>();
                foreach (var parameterTypeMatcher in bestParameterTypeMatchers)
                {
                    var parameterType = parameterTypeMatcher.ParameterType;
                    set.Add(parameterType);
                }
                var parameterTypes = set.ToList();

                parameterTypeCombinations.Add(parameterTypes);

                expressionTemplate
                        .Append(escape(text.Substring(pos, bestParameterTypeMatcher.GetMatchStart() - pos)))
                        .Append("{{{" + (paramCount++) + "}}}");
                pos = bestParameterTypeMatcher.GetMatchStart() + bestParameterTypeMatcher.GetMatchValue().Length;
            }
            else
            {
                break;
            }

            if (pos >= text.Length)
            {
                break;
            }
        }
        expressionTemplate.Append(escape(text.Substring(pos)));
        return new CombinatorialGeneratedExpressionFactory(expressionTemplate.ToString(), parameterTypeCombinations).GenerateExpressions();
    }

    private string escape(string s)
    {
        return s.Replace("(", "\\(")
                .Replace("{", "\\{{")
                .Replace("}", "}}")
                .Replace("/", "\\/");
    }

    private List<ParameterTypeMatcher> CreateParameterTypeMatchers(string text)
    {
        var parameterTypes = _parameterTypeRegistry.GetParameterTypes();
        var parameterTypeMatchers = new List<ParameterTypeMatcher>();
        foreach (var parameterType in parameterTypes)
        {
            if (parameterType.UseForSnippets)
            {
                parameterTypeMatchers.AddRange(CreateParameterTypeMatchers(parameterType, text));
            }
        }
        return parameterTypeMatchers;
    }

    private static List<ParameterTypeMatcher> CreateParameterTypeMatchers(IParameterType parameterType, string text)
    {
        var result = new List<ParameterTypeMatcher>();
        var captureGroupRegexps = parameterType.Regexps;
        foreach (var captureGroupRegexp in captureGroupRegexps)
        {
            var regexp = new Regex("(" + captureGroupRegexp + ")");
            result.Add(new ParameterTypeMatcher(parameterType, regexp, text));
        }
        return result;
    }
}
