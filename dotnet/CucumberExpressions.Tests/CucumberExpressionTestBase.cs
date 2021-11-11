using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions.Tests;

public abstract class CucumberExpressionTestBase : TestBase
{
    public class StubParameterType<T> : IParameterType
    {
        private readonly string _name;
        private readonly string[] _regexps;
        private readonly bool _useForSnippets;
        private readonly int _weight;

        public StubParameterType(string name, params string[] regexps) : this(name, regexps, true)
        {

        }

        public StubParameterType(string name, string[] regexps, bool useForSnippets = true, int weight = 0)
        {
            _name = name;
            _regexps = regexps;
            _useForSnippets = useForSnippets;
            _weight = weight;
        }

        public string[] RegexStrings => _regexps;
        public string Name => _name;
        public Type ParameterType => typeof(T);
        public int Weight => _weight;
        public bool UseForSnippets => _useForSnippets;
    }

    public class StubParameterTypeRegistry : IParameterTypeRegistry
    {
        private readonly List<IParameterType> _parameterTypes = new List<IParameterType>()
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
            .ToArray();
    }
}