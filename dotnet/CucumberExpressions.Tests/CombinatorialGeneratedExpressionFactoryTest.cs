using System;
using System.Collections.Generic;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;

public class CombinatorialGeneratedExpressionFactoryTest : CucumberExpressionTestBase {

    private const String WORD = "\\w+";

    [Fact]
    public void generates_multiple_expressions() {
        var first = new List<IParameterType>();
        first.Add(new StubParameterType<Color>("color", WORD));
        first.Add(new StubParameterType<CssColor>("csscolor", WORD));

        var second = new List<IParameterType>();
        second.Add(new StubParameterType<Date>("date", WORD));
        second.Add(new StubParameterType<DateTime>("datetime", WORD));
        second.Add(new StubParameterType<TimeSpan>("timestamp", WORD));
        var parameterTypeCombinations = new List<List<IParameterType>>()
        {
            first, second
        };

        CombinatorialGeneratedExpressionFactory factory = new CombinatorialGeneratedExpressionFactory(
                "I bought a {{{0}}} ball on {{{1}}}",
                parameterTypeCombinations
        );
        var generatedExpressions = factory.generateExpressions();
        var expressions = new List<String>();
        foreach (var generatedExpression in generatedExpressions) {
            var source = generatedExpression.getSource();
            expressions.Add(source);
        }
        expressions.Should().BeEquivalentTo(new [] {
                "I bought a {color} ball on {date}",
                "I bought a {color} ball on {datetime}",
                "I bought a {color} ball on {timestamp}",
                "I bought a {csscolor} ball on {date}",
                "I bought a {csscolor} ball on {datetime}",
                "I bought a {csscolor} ball on {timestamp}"
        });
    }

    public class Color {
        Color(String s) {
            Assert.NotNull(s);
        }
    }

    public class CssColor {
        CssColor(String s) {
            Assert.NotNull(s);
        }
    }

    public class Date {
        Date(String s) {
            Assert.NotNull(s);
        }
    }
}
