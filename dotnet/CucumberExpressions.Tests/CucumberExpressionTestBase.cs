using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using CucumberExpressions.Parsing;

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

    public class StubParameterTypeRegistry : IParameterTypeRegistry
    {
        private readonly List<IParameterType> _parameterTypes = new()
        {
            new StubParameterType<int>(ParameterTypeConstants.IntParameterName, ParameterTypeConstants.IntParameterRegexps, weight: 1000),
            new StubParameterType<string>(ParameterTypeConstants.StringParameterName, ParameterTypeConstants.StringParameterRegexps),
            new StubParameterType<string>(ParameterTypeConstants.WordParameterName, ParameterTypeConstants.WordParameterRegexps, false),
            new StubParameterType<float>(ParameterTypeConstants.FloatParameterName, ParameterTypeConstants.FloatParameterRegexpsEn, false),
            new StubParameterType<double>(ParameterTypeConstants.DoubleParameterName, ParameterTypeConstants.FloatParameterRegexpsEn)
        };

        public IParameterType LookupByTypeName(string name)
        {
            if (name == "unknown")
                return null;

            var paramType = _parameterTypes.FirstOrDefault(pt => pt.Name == name);
            if (paramType != null)
                return paramType;

            return new StubParameterType<string>("???", ".*");
        }

        public IEnumerable<IParameterType> GetParameterTypes()
        {
            return _parameterTypes;
        }

        public void DefineParameterType(IParameterType parameterType)
        {
            _parameterTypes.Add(parameterType);
        }

        public void Remove(IParameterType parameterType)
        {
            _parameterTypes.Remove(parameterType);
        }
    }

    private string TrimQuotes(string s)
    {
        if (s.Length >= 2 &&
            ((s[0] == '"' && s[^1] == '"') ||
             (s[0] == '\'' && s[^1] == '\'')))
            return s.Substring(1, s.Length - 2).Replace(@"\" + s[0], s[0].ToString());
        return s;
    }

    public object[] MatchExpression(IExpression expression, string text)
    {
        var group = new TreeRegexp(expression.Regex).Match(text);
        if (group == null)
            return null;

        var parameterTypes = (expression as CucumberExpression)?.ParameterTypes;

        var argGroups = group.Children ?? new List<Parsing.Group>();

        return argGroups
            .Select((g, i) => ConvertGroup(g, i < (parameterTypes?.Length ?? 0) ? parameterTypes[i] : null))
            .ToArray();
    }

    private object ConvertGroup(Parsing.Group group, IParameterType parameterType)
    {
        var value = group.Value;
        if (value == null)
            return null;

        var targetType = parameterType?.ParameterType;
        if (targetType == typeof(int))
            return int.Parse(value, CultureInfo.InvariantCulture);
        if (targetType == typeof(float))
            return float.Parse(value, NumberStyles.Float, CultureInfo.InvariantCulture);
        if (targetType == typeof(double))
            return double.Parse(value, NumberStyles.Float, CultureInfo.InvariantCulture);

        return TrimQuotes(value.Replace(@"\""", @"""").Replace(@"\'", @"'"));
    }
}