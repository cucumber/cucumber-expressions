using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using CucumberExpressions.Parsing;

namespace CucumberExpressions;

public class CucumberExpression : IExpression
{
    private static readonly Regex EscapePatternRe = new("([\\\\^\\[({$.|?*+})\\]])");

    private readonly List<IParameterType> _parameterTypes = new();
    private readonly TreeRegexp _treeRegexp;
    private readonly IParameterTypeRegistry _parameterTypeRegistry;
    public string Source { get; }

    public Regex Regex => _treeRegexp.Regex;
    public IParameterType[] ParameterTypes => _parameterTypes.ToArray();

    public CucumberExpression(string expression, IParameterTypeRegistry parameterTypeRegistry)
    {
        Source = expression;
        _parameterTypeRegistry = parameterTypeRegistry;

        CucumberExpressionParser parser = new CucumberExpressionParser();
        Ast.Node ast = parser.Parse(expression);
        var pattern = RewriteToRegex(ast);
        _treeRegexp = new TreeRegexp(pattern);
    }

    private string RewriteToRegex(Ast.Node node)
    {
        switch (node.Type)
        {
            case Ast.NodeType.TEXT_NODE:
                return EscapeRegex(node.Text);
            case Ast.NodeType.OPTIONAL_NODE:
                return RewriteOptional(node);
            case Ast.NodeType.ALTERNATION_NODE:
                return RewriteAlternation(node);
            case Ast.NodeType.ALTERNATIVE_NODE:
                return RewriteAlternative(node);
            case Ast.NodeType.PARAMETER_NODE:
                return RewriteParameter(node);
            case Ast.NodeType.EXPRESSION_NODE:
                return RewriteExpression(node);
            default:
                // Can't happen as long as the switch case is exhaustive
                throw new ArgumentException(node.Type.ToString(), nameof(node));
        }
    }

    private static string EscapeRegex(string text)
    {
        return EscapePatternRe.Replace(text, match => "\\" + match.Value);
    }

    private string RewriteOptional(Ast.Node node)
    {
        AssertNoParameters(node, astNode => CucumberExpressionException.CreateParameterIsNotAllowedInOptional(astNode, Source));
        AssertNoOptionals(node, astNode => CucumberExpressionException.CreateOptionalIsNotAllowedInOptional(astNode, Source));
        AssertNotEmpty(node, astNode => CucumberExpressionException.CreateOptionalMayNotBeEmpty(astNode, Source));
        return "(?:" + string.Join("", node.Nodes.Select(RewriteToRegex)) + ")?";
    }

    private string RewriteAlternation(Ast.Node node)
    {
        // Make sure the alternative parts aren't empty and don't contain parameter types
        foreach (var alternative in node.Nodes)
        {
            if (!alternative.Nodes.Any())
            {
                throw CucumberExpressionException.CreateAlternativeMayNotBeEmpty(alternative, Source);
            }
            AssertNotEmpty(alternative, astNode => CucumberExpressionException.CreateAlternativeMayNotExclusivelyContainOptionals(astNode, Source));
        }
        return "(?:" + string.Join("|", node.Nodes.Select(RewriteToRegex)) + ")";
    }

    private string RewriteAlternative(Ast.Node node)
    {
        return string.Join("", node.Nodes.Select(RewriteToRegex));
    }

    private string RewriteParameter(Ast.Node node)
    {
        string name = node.Text;
        IParameterType parameterType = _parameterTypeRegistry.LookupByTypeName(name);
        if (parameterType == null)
        {
            throw UndefinedParameterTypeException.CreateUndefinedParameterType(node, Source, name);
        }
        _parameterTypes.Add(parameterType);
        var regexps = GetParameterTypeRegexps(name, parameterType, out var shouldWrapWithCaptureGroup);

        var wrapGroupStart = shouldWrapWithCaptureGroup ? "(" : "(?:";

        if (regexps.Length == 1)
        {
            return wrapGroupStart + regexps[0] + ")";
        }
        return wrapGroupStart + "(?:" + string.Join(")|(?:", regexps) + "))";
    }

    protected virtual bool HandleStringType(string name, IParameterType parameterType, out string[] regexps, out bool shouldWrapWithCaptureGroup)
    {
        shouldWrapWithCaptureGroup = false;
        regexps = parameterType.RegexStrings
            .Select(RegexCaptureGroupRemover.RemoveInnerCaptureGroups)
            .ToArray();
        return true;
    }

    protected virtual string[] GetParameterTypeRegexps(string name, IParameterType parameterType, out bool shouldWrapWithCaptureGroup)
    {
        if (name == ParameterTypeConstants.StringParameterName && HandleStringType(name, parameterType, out var stringRegexps, out shouldWrapWithCaptureGroup))
        {
            return stringRegexps;
        }

        var regexps = parameterType.RegexStrings
            .Select(RegexCaptureGroupRemover.RemoveCaptureGroups)
            .ToArray();

        shouldWrapWithCaptureGroup = true;
        return regexps;
    }

    private string RewriteExpression(Ast.Node node)
    {
        return "^" + string.Join("", node.Nodes.Select(RewriteToRegex)) + "$";
    }

    private void AssertNotEmpty(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeWasNotEmptyException)
    {
        if (node.Nodes.FirstOrDefault(astNode => Ast.NodeType.TEXT_NODE.Equals(astNode.Type)) == null)
            throw createNodeWasNotEmptyException(node);
    }

    private void AssertNoParameters(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeContainedAParameterException)
    {
        AssertNoNodeOfType(Ast.NodeType.PARAMETER_NODE, node, createNodeContainedAParameterException);
    }

    private void AssertNoOptionals(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeContainedAnOptionalException)
    {
        AssertNoNodeOfType(Ast.NodeType.OPTIONAL_NODE, node, createNodeContainedAnOptionalException);
    }

    private void AssertNoNodeOfType(Ast.NodeType nodeType, Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createException)
    {
        var faultyNode = node.Nodes.FirstOrDefault(astNode => nodeType.Equals(astNode.Type));
        if (faultyNode != null)
            throw createException(faultyNode);
    }
}
