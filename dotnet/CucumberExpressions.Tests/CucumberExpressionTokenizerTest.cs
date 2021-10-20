using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using FluentAssertions;
using Xunit;

namespace CucumberExpressions.Tests;

public class CucumberExpressionTokenizerTest : TestBase
{
    private readonly CucumberExpressionTokenizer tokenizer = new();

    public static IEnumerable<object[]> acceptance_tests_pass_data()
        => GetTestDataFiles("cucumber-expression", "tokenizer")
            .Select(file => new object[]
            {
                Path.GetFileNameWithoutExtension(file), 
                ParseYaml<Expectation>(file)
            });

    [Theory, MemberData(nameof(acceptance_tests_pass_data))]
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
    public void Acceptance_tests_pass(string testCase, Expectation expectation)
    {
        if (expectation.Exception == null)
        {
            var tokens = tokenizer.tokenize(expectation.Expression);
            var expectedTokens = expectation.ExpectedTokens
                .Select(t => t.ToToken());
            tokens.Should().BeEquivalentTo(expectedTokens);
        }
        else
        {
            FluentActions.Invoking(() => tokenizer.tokenize(expectation.Expression))
                .Should().Throw<CucumberExpressionException>().WithMessage(expectation.Exception);
        }
    }

    public class Expectation
    {
        public string Expression;
        public List<YamlableToken> ExpectedTokens;
        public string Exception;
    }

    public class YamlableToken
    {
        public string Text;
        public Ast.Token.Type Type;
        public int Start;
        public int End;

        public Ast.Token ToToken()
        {
            return new Ast.Token(Text, Type, Start, End);
        }
    }
}
