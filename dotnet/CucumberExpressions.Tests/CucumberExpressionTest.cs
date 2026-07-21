using System;
using System.Collections.Generic;
using System.IO;
using System.Globalization;
using System.Linq;
using AwesomeAssertions;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class CucumberExpressionTest : CucumberExpressionTestBase
{
    private readonly IParameterTypeRegistry _parameterTypeRegistry = new ParameterTypeRegistry();
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


    [Theory, MemberData(nameof(acceptance_tests_pass_data))]
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
    public void Acceptance_tests_pass(string testCase, Expectation expectation)
    {
        _testOutputHelper.WriteLine(testCase);
        _testOutputHelper.WriteLine(ToYaml(expectation));
        if (expectation.exception == null)
        {
            CucumberExpression expression = new CucumberExpression(expectation.expression, _parameterTypeRegistry);
            _testOutputHelper.WriteLine(expression.Regex.ToString());
            var match = MatchExpression(expression, expectation.text);

            AssertArgumentsMatch(expectation.expected_args, match);
        }
        else
        {
            FluentActions.Invoking(() =>
                {
                    CucumberExpression expression = new CucumberExpression(expectation.expression, _parameterTypeRegistry);
                    MatchExpression(expression, expectation.text);
                })
                .Should().Throw<CucumberExpressionException>().WithMessage(expectation.exception);
        }
    }

    private static void AssertArgumentsMatch(List<string> expected, object[] actual)
    {
        if (expected == null || actual == null)
        {
            Assert.True(expected == null && actual == null);
            return;
        }

        Assert.Equal(expected.Count, actual.Length);
        foreach (var (want, got) in expected.Zip(actual))
            Assert.True(ValueMatches(want, got), $"expected {want ?? "null"}, got {got ?? "null"}");
    }

    private static bool ValueMatches(string expected, object actual)
        => actual switch
        {
            null => expected == null,
            float f => float.TryParse(expected, NumberStyles.Float, CultureInfo.InvariantCulture, out var e) && e == f,
            double d => double.TryParse(expected, NumberStyles.Float, CultureInfo.InvariantCulture, out var e) && e == d,
            _ => expected == Convert.ToString(actual, CultureInfo.InvariantCulture)
        };

    public class Expectation
    {
        public string expression;
        public string text;
        // ReSharper disable once InconsistentNaming
        public List<string> expected_args;
        public string exception;
    }

    // Misc tests

    [Fact]
    void exposes_source()
    {
        var expr = "I have {int} cuke(s)";
        Assert.Equal(expr, new CucumberExpression(expr, _parameterTypeRegistry).Source);
    }
}
