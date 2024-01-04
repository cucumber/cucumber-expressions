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

    public string[] MatchExpression(IExpression expression, string text)
    {
        var match = expression.Regex.Match(text);
        if (!match.Success)
            return null;
        return match.Groups.OfType<System.Text.RegularExpressions.Group>().Skip(1)
            .Where(g => g.Success)
            .Select(c => c.Value)
            .Select(v => v.StartsWith(".") ? "0" + v : v) // simulate float parsing with leading dot (.123)
            .Select(v => v.Replace(@"\""", @"""").Replace(@"\'", @"'")) // simulate quote masking
            .Select(TrimQuotes)
            .ToArray();
    }
}