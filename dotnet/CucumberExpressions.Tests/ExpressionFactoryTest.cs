using System;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;

public class ExpressionFactoryTest : CucumberExpressionTestBase
{

    [Fact]
    public void creates_cucumber_expression_by_default()
    {
        AssertCucumberExpression("strings are cukexp by default");
    }

    [Fact]
    public void creates_regular_expression_for_anchors()
    {
        AssertRegularExpression("^definitely a regexp$");
    }

    [Fact]
    public void creates_regular_expression_for_slashes()
    {
        AssertRegularExpression("surely a regexp", "/surely a regexp/");
    }

    [Fact]
    public void creates_cucumber_expression_for_parenthesis_with_alpha()
    {
        AssertCucumberExpression("this look(s) like a cukexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_escaped_parenthesis_with_regex_symbols()
    {
        AssertCucumberExpression("this looks\\( i.e: no regex symbols) like a cukexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_escaped_parenthesis_with_alpha()
    {
        AssertCucumberExpression("a heavy storm forecast \\(BF {int}+)");
    }

    [Fact]
    public void creates_cucumber_expression_for_parenthesis_with_regex_symbols()
    {
        AssertCucumberExpression("the temperature is (+){int} degrees celsius");
    }

    [Fact]
    public void creates_cucumber_expression_for_only_begin_anchor()
    {
        AssertRegularExpression("^this looks like a regexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_only_end_anchor()
    {
        AssertRegularExpression("this looks like a regexp$");
    }

    [Fact]
    public void creates_regular_expression_for_slashed_anchors()
    {
        AssertRegularExpression("^please remove slashes$", "/^please remove slashes$/");
    }

    [Fact]
    public void explains_cukexp_regexp_mix()
    {

        FluentActions.Invoking(() => CreateExpression("^the seller has {int} strike(s)[$"))
            .Should().Throw<CucumberExpressionException>().WithMessage(
                "You cannot use anchors (^ or $) in Cucumber Expressions. Please remove them from ^the seller has {int} strike(s)[$");
    }

    private void AssertRegularExpression(string expressionString)
    {
        AssertRegularExpression(expressionString, expressionString);
    }

    private void AssertRegularExpression(string expectedSource, string expressionString)
    {
        AssertExpression<RegularExpression>(expectedSource, expressionString);
    }

    private void AssertCucumberExpression(string expressionString)
    {
        AssertExpression<CucumberExpression>(expressionString, expressionString);
    }

    private void AssertExpression<TExpectedClass>(string expectedSource, string expressionString)
    {
        var expression = CreateExpression(expressionString);
        expression.Should().BeOfType<TExpectedClass>();
        if (expectedSource != null)
        {
            Assert.Equal(expectedSource, expression.Source);
        }
    }

    private IExpression CreateExpression(string expressionString)
    {
        return new ExpressionFactory(new StubParameterTypeRegistry()).CreateExpression(expressionString);
    }
}
