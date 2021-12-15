using System;
using System.Text.RegularExpressions;
using Xunit;

namespace CucumberExpressions.Tests;

public class RegularExpressionTest : CucumberExpressionTestBase
{
    [Fact]
    public void documentation_match_arguments()
    {
        var expr = new Regex("I have (\\d+) cukes? in my (\\w+) now");
        IExpression expression = new RegularExpression(expr);
        var match = MatchExpression(expression, "I have 7 cukes in my belly now");
        Assert.Equal("7", match[0]);
        Assert.Equal("belly", match[1]);
    }

    [Fact]
    public void exposes_source_and_regexp()
    {
        String regexp = "I have (\\d+) cukes? in my (.+) now";
        RegularExpression expression = new RegularExpression(new Regex(regexp));
        Assert.Equal(regexp, expression.Source);
        Assert.Equal(regexp, expression.Regex.ToString());
    }
}
