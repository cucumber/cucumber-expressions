using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions.Tests;

public abstract class CucumberExpressionTestBase : TestBase
{
    public class StubParameterType<T> : IParameterType
    {
        public string[] RegexStrings { get; }
        public string Name { get; }
        public int Weight { get; }
        public bool UseForSnippets { get; }

        public Type ParameterType => typeof(T);

        public StubParameterType(string name, params string[] regexps) : this(name, regexps, true)
        {
        }

        public StubParameterType(string name, string[] regexps, bool useForSnippets = true, int weight = 0)
        {
            Name = name;
            RegexStrings = regexps;
            UseForSnippets = useForSnippets;
            Weight = weight;
        }
    }

    public object[] MatchExpression(IExpression expression, string text)
    {
        if (expression is CucumberExpression cucumberExpression)
        {
            var arguments = cucumberExpression.Match(text);
            return arguments?.Select(argument => argument.GetValue()).ToArray();
        }

        var group = new Parsing.TreeRegexp(expression.Regex).Match(text);
        if (group == null)
            return null;

        var argumentGroups = group.Children ?? new List<Parsing.Group>();
        return argumentGroups.Select(g => (object)g.Value).ToArray();
    }
}
