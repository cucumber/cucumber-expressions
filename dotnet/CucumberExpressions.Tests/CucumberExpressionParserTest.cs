using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using CucumberExpressions.Parsing;
using FluentAssertions;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class CucumberExpressionParserTest : TestBase
{
    private readonly ITestOutputHelper _testOutputHelper;
	private readonly CucumberExpressionParser _parser = new();

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
			Ast.Node node = _parser.Parse(expectation.expression);
			node.Should().Be(expectation.expected_ast.ToNode());
		}
		else
		{
			FluentActions.Invoking(() => _parser.Parse(expectation.expression))
				.Should().Throw<CucumberExpressionException>().WithMessage(expectation.exception);
		}
	}

	public class Expectation
	{
		public string expression;
        // ReSharper disable once InconsistentNaming
        public YamlableNode expected_ast;
		public string exception;
	}
	public class YamlableNode
	{
		public Ast.NodeType type;
		public List<YamlableNode> nodes;
		public string token;
		public int start;
		public int end;

		public Ast.Node ToNode()
		{
			if (token != null)
			{
				return new Ast.Node(type, start, end, token);
			}
			else
			{
				return new Ast.Node(type, start, end, nodes.Select(n => n.ToNode()).ToArray());
			}
		}
	}
}
