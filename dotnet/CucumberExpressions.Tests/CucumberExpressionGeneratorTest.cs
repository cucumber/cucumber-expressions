using System;
using System.Collections.Generic;
using CucumberExpressions.Generation;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;

public class CucumberExpressionGeneratorTest : CucumberExpressionTestBase
{

    private readonly StubParameterTypeRegistry _parameterTypeRegistry = new();
    private readonly CucumberExpressionGenerator _generator;

    public CucumberExpressionGeneratorTest()
    {
        _generator = new CucumberExpressionGenerator(_parameterTypeRegistry);
    }

    [Fact]
    public void documents_expression_generation()
    {
        var generator = new CucumberExpressionGenerator(_parameterTypeRegistry);
        string undefinedStepText = "I have 2 cucumbers and 1.5 tomato";
        GeneratedExpression generatedExpression = generator.GenerateExpressions(undefinedStepText)[0];
        Assert.Equal("I have {int} cucumbers and {double} tomato", generatedExpression.GetSource());
        Assert.Equal(typeof(double), generatedExpression.GetParameterTypes()[1].ParameterType);
    }

    [Fact]
    public void generates_expression_for_no_args()
    {
        AssertExpression("hello", Array.Empty<string>(), "hello");
    }

    [Fact]
    public void generates_expression_with_escaped_left_parenthesis()
    {
        AssertExpression(
                "\\(iii)", Array.Empty<string>(),
                "(iii)");
    }

    [Fact]
    public void generates_expression_with_escaped_left_curly_brace()
    {
        AssertExpression(
                "\\{iii}", Array.Empty<string>(),
                "{iii}");
    }

    [Fact]
    public void generates_expression_with_escaped_slashes()
    {
        AssertExpression(
                "The {int}\\/{int}\\/{int} hey", new[] { "int1", "int2", "int3" },
                "The 1814/05/17 hey");
    }

    [Fact]
    public void generates_expression_for_int_arg()
    {
        AssertExpression(
                "I have {int} cukes", new[] { "int1" },
                "I have 2 cukes");
    }

    [Fact]
    public void generates_expression_for_double_arg()
    {
        AssertExpression(
                "I have {double} cukes", new[] { "double1" },
                "I have 2.5 cukes");
    }

    [Fact]
    public void generates_expression_for_int_double_arg()
    {
        AssertExpression(
                "I have {int} cukes and {double} euro", new[] { "int1", "double1" },
                "I have 2 cukes and 1.5 euro");
    }

    [Fact]
    public void generates_expression_for_numbers_with_symbols_and_currency()
    {
        AssertExpression(
                "Some ${double} of cukes at {int}° Celsius", new[] { "double1", "int1" },
                "Some $5000.00 of cukes at 42° Celsius");
    }

    [Fact]
    public void generates_expression_for_numbers_with_text_on_both_sides()
    {
        AssertExpression(
                "i18n", Array.Empty<string>(),
                "i18n");
    }

    [Fact]
    public void generates_expression_for_strings()
    {
        AssertExpression(
                "I like {string} and {string}", new[] { "string1", "string2" },
                "I like \"bangers\" and 'mash'");
    }

    [Fact]
    public void generates_expression_with_percent_sign()
    {
        AssertExpression(
                "I am {int}% foobar", new[] { "int1" },
                "I am 20% foobar");
    }

    [Fact]
    public void generates_expression_for_just_int()
    {
        AssertExpression(
                "{int}", new[] { "int1" },
                "99999");
    }

    [Fact]
    public void numbers_all_arguments_when_type_is_reserved_keyword()
    {
        AssertExpression(
                "I have {int} cukes and {int} euro", new[] { "int1", "int2" },
                "I have 2 cukes and 5 euro");
    }

    [Fact]
    public void numbers_only_second_argument_when_type_is_not_reserved_keyword()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<decimal>(
                "currency",
                "[A-Z]{3}"));
        AssertExpression(
                "I have a {currency} account and a {currency} account", new[] { "currency", "currency2" },
                "I have a EUR account and a GBP account");
    }

    [Fact]
    public void does_not_suggest_parameter_type_when_surrounded_by_alphanum()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
                "direction",
                "(up|down)"));
        AssertExpression(
                "I like muppets", Array.Empty<string>(),
                "I like muppets");
    }

    [Fact]
    public void does_suggest_parameter_type_when_surrounded_by_space()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "direction",
            "(up|down)"));
        AssertExpression(
                "it went {direction} and {direction}", new[] { "direction", "direction2" },
                "it went up and down");
    }

    [Fact]
    public void prefers_leftmost_match_when_there_is_overlap()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "right",
            "c d"));
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "left",
            "b c"));
        AssertExpression(
                "a {left} d e f g", new[] { "left" },
                "a b c d e f g");
    }

    [Fact]
    public void prefers_widest_match_when_pos_is_same()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "airport",
            "[A-Z]{3}"));
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "leg",
            "[A-Z]{3}-[A-Z]{3}"));
        AssertExpression(
                "leg {leg}", new[] { "leg" },
                "leg LHR-CDG");
    }

    [Fact]
    public void generates_all_combinations_of_expressions_when_several_parameter_types_match()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<decimal>(
            "currency",
            "x"));
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<DateTime>(
            "date",
            "x"));

        var generatedExpressions = _generator.GenerateExpressions("I have x and x and another x");
        var expressions = new List<string>();
        foreach (GeneratedExpression generatedExpression in generatedExpressions)
        {
            var source = generatedExpression.GetSource();
            expressions.Add(source);
        }
        Assert.Equal(new[] {
                "I have {currency} and {currency} and another {currency}",
                "I have {currency} and {currency} and another {date}",
                "I have {currency} and {date} and another {currency}",
                "I have {currency} and {date} and another {date}",
                "I have {date} and {currency} and another {currency}",
                "I have {date} and {currency} and another {date}",
                "I have {date} and {date} and another {currency}",
                "I have {date} and {date} and another {date}"
        }, expressions);
    }

    [Fact]
    public void exposes_transforms_in_generated_expression()
    {
        GeneratedExpression generatedExpression = _generator.GenerateExpressions("I have 2 cukes and 1.5 euro")[0];
        Assert.Equal(typeof(int), generatedExpression.GetParameterTypes()[0].ParameterType);
        Assert.Equal(typeof(double), generatedExpression.GetParameterTypes()[1].ParameterType);
    }

    [Fact]
    public void matches_parameter_types_with_optional_capture_groups()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "optional-flight",
            "(1st flight)?"));
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "optional-hotel",
            "(1 hotel)?"));
        var generatedExpressions = _generator.GenerateExpressions("I reach Stage 4: 1st flight -1 hotel");
        Assert.Equal("I reach Stage {int}: {optional-flight} {int} hotel", generatedExpressions[0].GetSource());
    }

    [Fact]
    public void generates_at_most_256_expressions()
    {
        for (int i = 0; i < 4; i++)
        {
            _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
                "my-type-" + i,
                "[a-z]"));
        }
        // This would otherwise generate 4^11=419430 expressions and consume just shy of 1.5GB.
        Assert.Equal(256, _generator.GenerateExpressions("a b c d e f g h i j k").Length);
    }

    [Fact]
    public void prefers_expression_with_longest_non_empty_match()
    {
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "exactly-one",
            "[a-z]"));
        _parameterTypeRegistry.DefineParameterType(new StubParameterType<string>(
            "zero-or-more",
            "[a-z]*"));

        var generatedExpressions = _generator.GenerateExpressions("a simple step");
        Assert.Equal(2, generatedExpressions.Length);
        Assert.Equal("{exactly-one} {zero-or-more} {zero-or-more}", generatedExpressions[0].GetSource());
        Assert.Equal("{zero-or-more} {zero-or-more} {zero-or-more}", generatedExpressions[1].GetSource());
    }

    private void AssertExpression(string expectedExpression, string[] expectedArgumentNames, string text)
    {
        GeneratedExpression generatedExpression = _generator.GenerateExpressions(text)[0];
        Assert.Equal(expectedExpression, generatedExpression.GetSource());
        Assert.Equal(expectedArgumentNames, generatedExpression.GetParameterNames());

        // Check that the generated expression matches the text
        var cucumberExpression = new CucumberExpression(generatedExpression.GetSource(), _parameterTypeRegistry);
        var match = MatchExpression(cucumberExpression, text);
        match.Should().NotBeNull($"Expected text '{text}' to match generated expression '{generatedExpression.GetSource()}'");
        Assert.Equal(expectedArgumentNames.Length, match.Length);
    }

}
