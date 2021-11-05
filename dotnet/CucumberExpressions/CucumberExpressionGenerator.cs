using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class CucumberExpressionGenerator {
    private readonly IParameterTypeRegistry parameterTypeRegistry;

    public CucumberExpressionGenerator(IParameterTypeRegistry parameterTypeRegistry) {
        this.parameterTypeRegistry = parameterTypeRegistry;
    }

    public List<GeneratedExpression> generateExpressions(String text) {
        var parameterTypeCombinations = new List<List<IParameterType>>();
        var parameterTypeMatchers = createParameterTypeMatchers(text);
        StringBuilder expressionTemplate = new StringBuilder();
        int pos = 0;
        int paramCount = 0;
        while (true) {
            var matchingParameterTypeMatchers = new List<ParameterTypeMatcher>();

            foreach (var parameterTypeMatcher in parameterTypeMatchers) {
                if (parameterTypeMatcher.advanceToAndFind(pos)) {
                    matchingParameterTypeMatchers.Add(parameterTypeMatcher);
                }
            }

            if (matchingParameterTypeMatchers.Any()) {
                matchingParameterTypeMatchers.Sort();

                // Find all the best parameter type matchers, they are all candidates.
                var bestParameterTypeMatcher = matchingParameterTypeMatchers[0];
                var bestParameterTypeMatchers = new List<ParameterTypeMatcher>();
                foreach (var m in matchingParameterTypeMatchers) {
                    if (m.CompareTo(bestParameterTypeMatcher) == 0) {
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
                foreach (var parameterTypeMatcher in bestParameterTypeMatchers) {
                    var parameterType = parameterTypeMatcher.getParameterType();
                    set.Add(parameterType);
                }
                var parameterTypes = set.ToList();

                parameterTypeCombinations.Add(parameterTypes);

                expressionTemplate
                        .Append(escape(text.Substring(pos, bestParameterTypeMatcher.start() - pos)))
                        .Append("{{{" + (paramCount++) + "}}}");
                pos = bestParameterTypeMatcher.start() + bestParameterTypeMatcher.group().Length;
            } else {
                break;
            }

            if (pos >= text.Length) {
                break;
            }
        }
        expressionTemplate.Append(escape(text.Substring(pos)));
        return new CombinatorialGeneratedExpressionFactory(expressionTemplate.ToString(), parameterTypeCombinations).generateExpressions();
    }

    private String escape(String s) {
        return s.Replace("(", "\\(")
                .Replace("{", "\\{{")
                .Replace("}", "}}")
                .Replace("/", "\\/");
    }

    private List<ParameterTypeMatcher> createParameterTypeMatchers(String text) {
        var parameterTypes = parameterTypeRegistry.getParameterTypes();
        var parameterTypeMatchers = new List<ParameterTypeMatcher>();
        foreach (var parameterType in parameterTypes) {
            if (parameterType.useForSnippets()) {
                parameterTypeMatchers.AddRange(createParameterTypeMatchers(parameterType, text));
            }
        }
        return parameterTypeMatchers;
    }

    private static List<ParameterTypeMatcher> createParameterTypeMatchers(IParameterType parameterType, String text) {
        var result = new List<ParameterTypeMatcher>();
        var captureGroupRegexps = parameterType.getRegexps();
        foreach (var captureGroupRegexp in captureGroupRegexps)
        {
            var regexp = new Regex("(" + captureGroupRegexp + ")");
            result.Add(new ParameterTypeMatcher(parameterType, regexp, text));
        }
        return result;
    }

}
