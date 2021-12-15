using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class CucumberExpressionTransformationTest : CucumberExpressionTestBase
{
    private readonly StubParameterTypeRegistry _parameterTypeRegistry = new();
    private readonly ITestOutputHelper _testOutputHelper;

    public CucumberExpressionTransformationTest(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
        var oldIntParameterType = _parameterTypeRegistry.LookupByTypeName("int");
        _parameterTypeRegistry.Remove(oldIntParameterType);
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<int>(ParameterTypeConstants.IntParameterName, 
            new []{ ParameterTypeConstants.IntParameterRegex, "\\d+" }, weight: 1000));
    }

    public static IEnumerable<object[]> acceptance_tests_pass_data()
        => GetTestDataFiles("cucumber-expression", "transformation")
            //.Where(file => file.Contains("matches-single-quoted-string-with-escaped-single-quote"))
            .Select(file => new object[]
            {
                Path.GetFileNameWithoutExtension(file),
                ParseYaml<Expectation>(file)
            });


    [Theory, MemberData(nameof(acceptance_tests_pass_data))]
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
    public void Acceptance_tests_pass(string testCase, Expectation expectation) {
        _testOutputHelper.WriteLine(testCase);
        _testOutputHelper.WriteLine(ToYaml(expectation));
        CucumberExpression expression = new CucumberExpression(expectation.expression, _parameterTypeRegistry);
        Assert.Equal(expectation.expected_regex, expression.Regex.ToString());
    }

    public class Expectation {
        public string expression;
        // ReSharper disable once InconsistentNaming
        public string expected_regex;
    }
}
