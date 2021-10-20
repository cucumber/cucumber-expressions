using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using FluentAssertions;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class CucumberExpressionParserTest : TestBase
{
    private readonly ITestOutputHelper _testOutputHelper;
	private readonly CucumberExpressionParser parser = new();

    public CucumberExpressionParserTest(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;
    }

    public static IEnumerable<object[]> acceptance_tests_pass_data()
		=> GetTestDataFiles("cucumber-expression", "parser")
			.Select(file => new object[]
			{
				Path.GetFileNameWithoutExtension(file),
				ParseYaml<Expectation>(file)
			});

	[Theory, MemberData(nameof(acceptance_tests_pass_data))]
	[System.Diagnostics.CodeAnalysis.SuppressMessage("Usage", "xUnit1026:Theory methods should use all of their parameters", Justification = "<Pending>")]
	public void acceptance_tests_pass(string testCase, Expectation expectation)
	{
		_testOutputHelper.WriteLine(ToYaml(expectation));
		if (expectation.exception == null)
		{
			Ast.Node node = parser.parse(expectation.expression);
			node.Should().Be(expectation.expected_ast.toNode());
		}
		else
		{
			FluentActions.Invoking(() => parser.parse(expectation.expression))
				.Should().Throw<CucumberExpressionException>().WithMessage(expectation.exception);
		}
	}

	public class Expectation
	{
		public String expression;
		public YamlableNode expected_ast;
		public String exception;
	}
	public class YamlableNode
	{
		public Ast.Node.Type type;
		public List<YamlableNode> nodes;
		public String token;
		public int start;
		public int end;

		public Ast.Node toNode()
		{
			if (token != null)
			{
				return new Ast.Node(type, start, end, token);
			}
			else
			{
				return new Ast.Node(type, start, end, nodes.Select(n => n.toNode()).ToList());
			}
		}
	}
}
