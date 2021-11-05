using System;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;


public class ExpressionFactoryTest : CucumberExpressionTestBase {

    [Fact]
    public void creates_cucumber_expression_by_default() {
        assertCucumberExpression("strings are cukexp by default");
    }

    [Fact]
    public void creates_regular_expression_for_anchors() {
        assertRegularExpression("^definitely a regexp$");
    }

    [Fact]
    public void creates_regular_expression_for_slashes() {
        assertRegularExpression("surely a regexp", "/surely a regexp/");
    }

    [Fact]
    public void creates_cucumber_expression_for_parenthesis_with_alpha() {
        assertCucumberExpression("this look(s) like a cukexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_escaped_parenthesis_with_regex_symbols() {
        assertCucumberExpression("this looks\\( i.e: no regex symbols) like a cukexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_escaped_parenthesis_with_alpha() {
        assertCucumberExpression("a heavy storm forecast \\(BF {int}+)");
    }

    [Fact]
    public void creates_cucumber_expression_for_parenthesis_with_regex_symbols() {
        assertCucumberExpression("the temperature is (+){int} degrees celsius");
    }

    [Fact]
    public void creates_cucumber_expression_for_only_begin_anchor() {
        assertRegularExpression("^this looks like a regexp");
    }

    [Fact]
    public void creates_cucumber_expression_for_only_end_anchor() {
        assertRegularExpression("this looks like a regexp$");
    }

    [Fact]
    public void creates_regular_expression_for_slashed_anchors() {
        assertRegularExpression("^please remove slashes$", "/^please remove slashes$/");
    }

    [Fact]
    public void explains_cukexp_regexp_mix()
    {

        FluentActions.Invoking(() => createExpression("^the seller has {int} strike(s)[$"))
            .Should().Throw<CucumberExpressionException>().WithMessage(
                "You cannot use anchors (^ or $) in Cucumber Expressions. Please remove them from ^the seller has {int} strike(s)[$");
    }

    private void assertRegularExpression(String expressionString) {
        assertRegularExpression(expressionString, expressionString);
    }

    private void assertRegularExpression(String expectedSource, String expressionString) {
        assertExpression<RegularExpression>(expectedSource, expressionString);
    }

    private void assertCucumberExpression(String expressionString) {
        assertExpression<CucumberExpression>(expressionString, expressionString);
    }

    private void assertExpression<expectedClass>(String expectedSource, String expressionString) {
        var expression = createExpression(expressionString);
        expression.Should().BeOfType<expectedClass>();
        if (expectedSource != null) {
            Assert.Equal(expectedSource, expression.getSource());
        }
    }

    private Expression createExpression(String expressionString) {
        return new ExpressionFactory(new StubParameterTypeRegistry()).createExpression(expressionString);
    }
}
