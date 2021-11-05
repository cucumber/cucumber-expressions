using System;
using CucumberExpressions.Ast;

namespace CucumberExpressions;

public class UndefinedParameterTypeException : CucumberExpressionException
{
    public string UndefinedParameterTypeName { get; }

    public UndefinedParameterTypeException(string message, string undefinedParameterTypeName) : base(message)
    {
        UndefinedParameterTypeName = undefinedParameterTypeName;
    }

    internal static CucumberExpressionException CreateUndefinedParameterType(Node node, string expression, string undefinedParameterTypeName)
    {
        return new UndefinedParameterTypeException(GetMessage(
                node.Start,
                expression,
                PointAt(node),
                "Undefined parameter type '" + undefinedParameterTypeName + "'",
                "Please register a ParameterType for '" + undefinedParameterTypeName + "'"), undefinedParameterTypeName);
    }
}
