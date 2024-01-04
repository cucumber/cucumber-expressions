using System;
using CucumberExpressions.Ast;

namespace CucumberExpressions.Parsing;

public class CucumberExpressionParserResult
{
    public int Consumed { get; }
    public Node[] Ast { get; }

    public CucumberExpressionParserResult(int consumed, params Node[] ast)
    {
        Consumed = consumed;
        Ast = ast ?? Array.Empty<Node>();
    }
}