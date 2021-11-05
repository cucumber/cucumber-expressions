using System;
using System.Collections.Generic;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;


public class CucumberExpressionGeneratorTest : CucumberExpressionTestBase
{

    private readonly StubParameterTypeRegistry parameterTypeRegistry = new StubParameterTypeRegistry();
    private readonly CucumberExpressionGenerator generator;

    public CucumberExpressionGeneratorTest()
    {
        generator = new CucumberExpressionGenerator(parameterTypeRegistry);
    }

    [Fact]
    public void documents_expression_generation() {
        CucumberExpressionGenerator generator = new CucumberExpressionGenerator(parameterTypeRegistry);
        String undefinedStepText = "I have 2 cucumbers and 1.5 tomato";
        GeneratedExpression generatedExpression = generator.generateExpressions(undefinedStepText)[0];
        Assert.Equal("I have {int} cucumbers and {double} tomato", generatedExpression.getSource());
        Assert.Equal(typeof(double), generatedExpression.getParameterTypes()[1].getType());
    }

    [Fact]
    public void generates_expression_for_no_args() {
        assertExpression("hello", Array.Empty<string>(), "hello");
    }

    [Fact]
    public void generates_expression_with_escaped_left_parenthesis() {
        assertExpression(
                "\\(iii)", Array.Empty<string>(),
                "(iii)");
    }

    [Fact]
    public void generates_expression_with_escaped_left_curly_brace() {
        assertExpression(
                "\\{iii}", Array.Empty<string>(),
                "{iii}");
    }

    [Fact]
    public void generates_expression_with_escaped_slashes() {
        assertExpression(
                "The {int}\\/{int}\\/{int} hey", new[] {"int1", "int2", "int3"},
                "The 1814/05/17 hey");
    }

    [Fact]
    public void generates_expression_for_int_arg() {
        assertExpression(
                "I have {int} cukes", new[] {"int1"},
                "I have 2 cukes");
    }

    [Fact]
    public void generates_expression_for_double_arg() {
        assertExpression(
                "I have {double} cukes", new[] { "double1" },
                "I have 2.5 cukes");
    }

    [Fact]
    public void generates_expression_for_int_double_arg() {
        assertExpression(
                "I have {int} cukes and {double} euro", new[] {"int1", "double1"},
                "I have 2 cukes and 1.5 euro");
    }

    [Fact]
    public void generates_expression_for_numbers_with_symbols_and_currency() {
        assertExpression(
                "Some ${double} of cukes at {int}° Celsius", new[] {"double1", "int1"},
                "Some $5000.00 of cukes at 42° Celsius");
    }

    [Fact]
    public void generates_expression_for_numbers_with_text_on_both_sides() {
        assertExpression(
                "i18n", Array.Empty<string>(),
                "i18n");
    }

    [Fact]
    public void generates_expression_for_strings() {
        assertExpression(
                "I like {string} and {string}", new[] {"string", "string2"},
                "I like \"bangers\" and 'mash'");
    }

    [Fact]
    public void generates_expression_with_percent_sign() {
        assertExpression(
                "I am {int}% foobar", new[] {"int1"},
                "I am 20% foobar");
    }

    [Fact]
    public void generates_expression_for_just_int() {
        assertExpression(
                "{int}", new[] {"int1"},
                "99999");
    }

    [Fact]
    public void numbers_all_arguments_when_type_is_reserved_keyword() {
        assertExpression(
                "I have {int} cukes and {int} euro", new[] {"int1", "int2"},
                "I have 2 cukes and 5 euro");
    }

    [Fact]
    public void numbers_only_second_argument_when_type_is_not_reserved_keyword() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<decimal>(
                "currency",
                "[A-Z]{3}"));
        assertExpression(
                "I have a {currency} account and a {currency} account", new[] {"currency", "currency2"},
                "I have a EUR account and a GBP account");
    }

    [Fact]
    public void does_not_suggest_parameter_type_when_surrounded_by_alphanum() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
                "direction",
                "(up|down)"));
        assertExpression(
                "I like muppets", Array.Empty<string>(),
                "I like muppets");
    }

    [Fact]
    public void does_suggest_parameter_type_when_surrounded_by_space() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "direction",
            "(up|down)"));
        assertExpression(
                "it went {direction} and {direction}", new[] {"direction", "direction2"},
                "it went up and down");
    }

    [Fact]
    public void prefers_leftmost_match_when_there_is_overlap() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "right",
            "c d"));
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "left",
            "b c"));
        assertExpression(
                "a {left} d e f g", new[] {"left"},
                "a b c d e f g");
    }

    [Fact]
    public void prefers_widest_match_when_pos_is_same() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "airport",
            "[A-Z]{3}"));
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "leg",
            "[A-Z]{3}-[A-Z]{3}"));
        assertExpression(
                "leg {leg}", new[] {"leg"},
                "leg LHR-CDG");
    }

    [Fact]
    public void generates_all_combinations_of_expressions_when_several_parameter_types_match() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<decimal>(
            "currency",
            "x"));
        parameterTypeRegistry.defineParameterType(new StubParameterType<DateTime>(
            "date",
            "x"));

        var generatedExpressions = generator.generateExpressions("I have x and x and another x");
        var expressions = new List<String>();
        foreach (GeneratedExpression generatedExpression in generatedExpressions) {
            var source = generatedExpression.getSource();
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
    public void exposes_transforms_in_generated_expression() {
        GeneratedExpression generatedExpression = generator.generateExpressions("I have 2 cukes and 1.5 euro")[0];
        Assert.Equal(typeof(int), generatedExpression.getParameterTypes()[0].getType());
        Assert.Equal(typeof(double), generatedExpression.getParameterTypes()[1].getType());
    }

    [Fact]
    public void matches_parameter_types_with_optional_capture_groups() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "optional-flight",
            "(1st flight)?"));
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "optional-hotel",
            "(1 hotel)?"));
        List<GeneratedExpression> generatedExpressions = generator.generateExpressions("I reach Stage 4: 1st flight -1 hotel");
        Assert.Equal("I reach Stage {int}: {optional-flight} {int} hotel", generatedExpressions[0].getSource());
    }

    [Fact]
    public void generates_at_most_256_expressions() {
        for (int i = 0; i < 4; i++) {
            parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
                "my-type-" + i,
                "[a-z]"));
        }
        // This would otherwise generate 4^11=419430 expressions and consume just shy of 1.5GB.
        Assert.Equal(256, generator.generateExpressions("a b c d e f g h i j k").Count);
    }

    [Fact]
    public void prefers_expression_with_longest_non_empty_match() {
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "exactly-one",
            "[a-z]"));
        parameterTypeRegistry.defineParameterType(new StubParameterType<string>(
            "zero-or-more",
            "[a-z]*"));

        List<GeneratedExpression> generatedExpressions = generator.generateExpressions("a simple step");
        Assert.Equal(2, generatedExpressions.Count);
        Assert.Equal("{exactly-one} {zero-or-more} {zero-or-more}", generatedExpressions[0].getSource());
        Assert.Equal("{zero-or-more} {zero-or-more} {zero-or-more}", generatedExpressions[1].getSource());
    }

    private void assertExpression(String expectedExpression, string[] expectedArgumentNames, String text) {
        GeneratedExpression generatedExpression = generator.generateExpressions(text)[0];
        Assert.Equal(expectedExpression, generatedExpression.getSource());
        Assert.Equal(expectedArgumentNames, generatedExpression.getParameterNames());

        // Check that the generated expression matches the text
        var cucumberExpression = new CucumberExpression(generatedExpression.getSource(), parameterTypeRegistry);
        var match = MatchExpression(cucumberExpression, text);
        match.Should().NotBeNull($"Expected text '{text}' to match generated expression '{generatedExpression.getSource()}'");
        Assert.Equal(expectedArgumentNames.Length, match.Length);
    }

}
