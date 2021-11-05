using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using FluentAssertions;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class CucumberExpressionTest : TestBase {

    class StubParameterType : IParameterType
    {
        private readonly string[] _regexps;

        public StubParameterType(params string[] regexps)
        {
            this._regexps = regexps == null || regexps.Length == 0 ? new []{ ".*" } : regexps;
        }

        public string[] getRegexps()
        {
            return _regexps.ToArray();
        }
    }
    class StubParameterTypeRegistry : IParameterTypeRegistry
    {
        public IParameterType lookupByTypeName(string name)
        {
            switch (name)
            {
                case "int":
                    return new StubParameterType("-?\\d+");
                case "string":
                    return new StubParameterType("\"([^\"\\\\]*(\\\\.[^\"\\\\]*)*)\"", "'([^'\\\\]*(\\\\.[^'\\\\]*)*)'");
                case "unknown":
                    return null;
            }

            return new StubParameterType();
        }
    }

    private readonly IParameterTypeRegistry _parameterTypeRegistry = new StubParameterTypeRegistry();
    private readonly ITestOutputHelper _testOutputHelper;

    public CucumberExpressionTest(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    public static IEnumerable<object[]> acceptance_tests_pass_data()
        => GetTestDataFiles("cucumber-expression", "matching")
            //.Where(file => file.Contains("matches-single-quoted-string-with-escaped-single-quote"))
            .Select(file => new object[]
            {
                Path.GetFileNameWithoutExtension(file),
                ParseYaml<Expectation>(file)
            });

    public string[] MatchExpression(Expression expression, string text)
    {
        var match = expression.getRegexp().Match(text);
        if (!match.Success)
            return null;
        return match.Groups.OfType<System.Text.RegularExpressions.Group>().Skip(1)
            .Where(g => g.Success)
            .Select(c => c.Value)
            .Select(v => v.StartsWith(".") ? "0" + v : v) // simulate float parsing with leading dot (.123)
            .Select(v => v.Replace(@"\""", @"""").Replace(@"\'", @"'")) // simulate quote masking
            .ToArray();
    }

    [Theory, MemberData(nameof(acceptance_tests_pass_data))]
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
    public void Acceptance_tests_pass(string testCase, Expectation expectation) {
        _testOutputHelper.WriteLine(testCase);
        _testOutputHelper.WriteLine(ToYaml(expectation));
        if (expectation.exception == null) {
            CucumberExpression expression = new CucumberExpression(expectation.expression, _parameterTypeRegistry);
            _testOutputHelper.WriteLine(expression.getRegexp().ToString());
            var match = MatchExpression(expression, expectation.text);

            var values = match == null ? null : match
                .ToList();

            Assert.Equal(expectation.expected_args, values);
        } else {
            FluentActions.Invoking(() =>
                {
                    CucumberExpression expression = new CucumberExpression(expectation.expression, _parameterTypeRegistry);
                    MatchExpression(expression, expectation.text);
                })
                .Should().Throw<CucumberExpressionException>().WithMessage(expectation.exception);
        }
    }

    public class Expectation {
        public String expression;
        public String text;
        public List<string> expected_args;
        public String exception;
    }

    // Misc tests

    [Fact]
    void exposes_source()
    {
        var expr = "I have {int} cuke(s)";
        Assert.Equal(expr, new CucumberExpression(expr, _parameterTypeRegistry).getSource());
    }
}
