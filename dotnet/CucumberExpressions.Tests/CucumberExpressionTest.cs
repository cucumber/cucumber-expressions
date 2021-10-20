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

    private readonly IParameterTypeRegistry parameterTypeRegistry = new StubParameterTypeRegistry();
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
            .Select(v => v.StartsWith(".") ? "0" + v : v)
            .Select(v => v.Replace(@"\""", @"""").Replace(@"\'", @"'"))
            //.Select(TrimQuotes)
            .ToArray();
    }

    private string TrimQuotes(string s)
    {
        if (s.Length >= 2 &&
            ((s[0] == '"' && s[^1] == '"') ||
            (s[0] == '\'' && s[^1] == '\'')))
            return s.Substring(1, s.Length - 2).Replace(@"\" + s[0], s[0].ToString());
        return s;
    }

    [Theory, MemberData(nameof(acceptance_tests_pass_data))]
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
    public void Acceptance_tests_pass(string testCase, Expectation expectation) {
        _testOutputHelper.WriteLine(testCase);
        _testOutputHelper.WriteLine(ToYaml(expectation));
        if (expectation.exception == null) {
            CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
            _testOutputHelper.WriteLine(expression.getRegexp().ToString());
            var match = MatchExpression(expression, expectation.text);

            var values = match == null ? null : match
                .ToList();

            Assert.Equal(expectation.expected_args, values);
        } else {
            FluentActions.Invoking(() =>
                {
                    CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
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

    //[Fact]
    //void exposes_source() {
    //    String expr = "I have {int} cuke(s)";
    //    Assert.Equal(expr, new CucumberExpression(expr, new ParameterTypeRegistry(Locale.ENGLISH)).getSource());
    //}

    //// Java-specific
    //[Fact]
    //void matches_anonymous_parameter_type_with_hint() {
    //    Assert.Equal(singletonList(0.22f), match("{}", "0.22", Float.class));
    //}

    //[Fact]
    //void documents_match_arguments() {
    //    String expr = "I have {int} cuke(s)";
    //    Expression expression = new CucumberExpression(expr, parameterTypeRegistry);
    //    List<Argument<?>> args = expression.match("I have 7 cukes");
    //    Assert.Equal(7, args.get(0).getValue());
    //}

    //[Fact]
    //void matches_byte() {
    //    Assert.Equal(singletonList(Byte.MAX_VALUE), match("{byte}", "127"));
    //}

    //[Fact]
    //void matches_short() {
    //    Assert.Equal(singletonList(Short.MAX_VALUE), match("{short}", String.valueOf(Short.MAX_VALUE)));
    //}

    //[Fact]
    //void matches_long() {
    //    Assert.Equal(singletonList(Long.MAX_VALUE), match("{long}", String.valueOf(Long.MAX_VALUE)));
    //}

    //[Fact]
    //void matches_biginteger() {
    //    BigInteger bigInteger = BigInteger.valueOf(Long.MAX_VALUE);
    //    bigInteger = bigInteger.pow(10);
    //    Assert.Equal(singletonList(bigInteger), match("{biginteger}", bigInteger.toString()));
    //}

    //[Fact]
    //void matches_bigdecimal() {
    //    BigDecimal bigDecimal = BigDecimal.valueOf(Math.PI);
    //    Assert.Equal(singletonList(bigDecimal), match("{bigdecimal}", bigDecimal.toString()));
    //}

    //[Fact]
    //void matches_double_with_comma_for_locale_using_comma() {
    //    List<?> values = match("{double}", "1,22", Locale.FRANCE);
    //    Assert.Equal(singletonList(1.22), values);
    //}

    //[Fact]
    //void matches_float_with_zero() {
    //    List<?> values = match("{float}", "0", Locale.ENGLISH);
    //    Assert.Equal(0.0f, values.get(0));
    //}

    //[Fact]
    //void unmatched_optional_groups_have_null_values() {
    //    ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
    //    parameterTypeRegistry.defineParameterType(new ParameterType<>(
    //            "textAndOrNumber",
    //            singletonList("([A-Z]+)?(?: )?([0-9]+)?"),
    //            new TypeReference<List<String>>() {
    //            }.getType(),
    //            new CaptureGroupTransformer<List<String>>() {
    //                @Override
    //                public List<String> transform(String... args) {
    //                    return asList(args);
    //                }
    //            },
    //            false,
    //            false)
    //    );
    //    assertThat(match("{textAndOrNumber}", "TLA", parameterTypeRegistry), is(singletonList(asList("TLA", null))));
    //    assertThat(match("{textAndOrNumber}", "123", parameterTypeRegistry), is(singletonList(asList(null, "123"))));
    //}

    //private List<?> match(String expr, String text, Type... typeHints) {
    //    return match(expr, text, parameterTypeRegistry, typeHints);
    //}

    //private List<?> match(String expr, String text, Locale locale, Type... typeHints) {
    //    ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(locale);
    //    return match(expr, text, parameterTypeRegistry, typeHints);
    //}

    //private List<?> match(String expr, String text, ParameterTypeRegistry parameterTypeRegistry, Type... typeHints) {
    //    CucumberExpression expression = new CucumberExpression(expr, parameterTypeRegistry);
    //    List<Argument<?>> args = expression.match(text, typeHints);
    //    if (args == null) {
    //        return null;
    //    } else {
    //        List<Object> list = new ArrayList<>();
    //        for (Argument<?> arg : args) {
    //            Object value = arg.getValue();
    //            list.add(value);
    //        }
    //        return list;
    //    }
    //}
}
