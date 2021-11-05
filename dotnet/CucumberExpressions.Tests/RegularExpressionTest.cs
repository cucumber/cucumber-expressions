using System;
using System.Text.RegularExpressions;
using Xunit;

namespace CucumberExpressions.Tests;

public class RegularExpressionTest : CucumberExpressionTestBase
{
    private readonly StubParameterTypeRegistry _parameterTypeRegistry = new();

    [Fact]
    public void documentation_match_arguments() {
        var expr = new Regex("I have (\\d+) cukes? in my (\\w+) now");
        Expression expression = new RegularExpression(expr, _parameterTypeRegistry);
        var match = MatchExpression(expression, "I have 7 cukes in my belly now");
        Assert.Equal("7", match[0]);
        Assert.Equal("belly", match[1]);
    }

    [Fact]
    public void exposes_source_and_regexp() {
        String regexp = "I have (\\d+) cukes? in my (.+) now";
        RegularExpression expression = new RegularExpression(new Regex(regexp), _parameterTypeRegistry);
        Assert.Equal(regexp, expression.getSource());
        Assert.Equal(regexp, expression.getRegexp().ToString());
    }
}
