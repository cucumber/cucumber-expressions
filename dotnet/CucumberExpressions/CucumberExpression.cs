using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class CucumberExpression : Expression
{
    private static readonly Regex ESCAPE_PATTERN = new("([\\\\^\\[({$.|?*+})\\]])");

    private readonly List<IParameterType> parameterTypes = new();
    private readonly String source;
    private readonly TreeRegexp treeRegexp;
    private readonly IParameterTypeRegistry parameterTypeRegistry;

    public CucumberExpression(String expression, IParameterTypeRegistry parameterTypeRegistry)
    {
        this.source = expression;
        this.parameterTypeRegistry = parameterTypeRegistry;

        CucumberExpressionParser parser = new CucumberExpressionParser();
        Ast.Node ast = parser.parse(expression);
        String pattern = rewriteToRegex(ast);
        treeRegexp = new TreeRegexp(pattern);
    }

    private String rewriteToRegex(Ast.Node node)
    {
        switch (node.type)
        {
            case Ast.Node.Type.TEXT_NODE:
                return escapeRegex(node.text);
            case Ast.Node.Type.OPTIONAL_NODE:
                return rewriteOptional(node);
            case Ast.Node.Type.ALTERNATION_NODE:
                return rewriteAlternation(node);
            case Ast.Node.Type.ALTERNATIVE_NODE:
                return rewriteAlternative(node);
            case Ast.Node.Type.PARAMETER_NODE:
                return rewriteParameter(node);
            case Ast.Node.Type.EXPRESSION_NODE:
                return rewriteExpression(node);
            default:
                // Can't happen as long as the switch case is exhaustive
                throw new ArgumentException(node.type.ToString(), nameof(node));
        }
    }

    private static String escapeRegex(String text)
    {
        return ESCAPE_PATTERN.Replace(text, match => "\\" + match.Value);
    }

    private String rewriteOptional(Ast.Node node)
    {
        assertNoParameters(node, astNode => CucumberExpressionException.createParameterIsNotAllowedInOptional(astNode, source));
        assertNoOptionals(node, astNode => CucumberExpressionException.createOptionalIsNotAllowedInOptional(astNode, source));
        assertNotEmpty(node, astNode => CucumberExpressionException.createOptionalMayNotBeEmpty(astNode, source));
        return "(?:" + string.Join("", node.nodes.Select(rewriteToRegex)) +  ")?";
    }

    private String rewriteAlternation(Ast.Node node)
    {
        // Make sure the alternative parts aren't empty and don't contain parameter types
        foreach (var alternative in node.nodes)
        {
            if (!alternative.nodes.Any())
            {
                throw CucumberExpressionException.createAlternativeMayNotBeEmpty(alternative, source);
            }
            assertNotEmpty(alternative, astNode=> CucumberExpressionException.createAlternativeMayNotExclusivelyContainOptionals(astNode, source));
        }
        return "(?:" + string.Join("|", node.nodes.Select(rewriteToRegex)) + ")";
    }

    private String rewriteAlternative(Ast.Node node)
    {
        return string.Join("", node.nodes.Select(rewriteToRegex));
    }

    private String rewriteParameter(Ast.Node node)
    {
        String name = node.text;
        IParameterType parameterType = parameterTypeRegistry.lookupByTypeName(name);
        if (parameterType == null)
        {
            throw UndefinedParameterTypeException.createUndefinedParameterType(node, source, name);
        }
        parameterTypes.Add(parameterType);
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
        regexps = parameterType
            .getRegexps()
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

        var regexps = parameterType
            .getRegexps()
            .Select(RegexCaptureGroupRemover.RemoveCaptureGroups)
            .ToArray();

        shouldWrapWithCaptureGroup = true;
        return regexps;
    }

    private String rewriteExpression(Ast.Node node)
    {
        return "^" + string.Join("", node.nodes.Select(rewriteToRegex)) + "$";
    }

    private void assertNotEmpty(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeWasNotEmptyException)
    {
        if (node.nodes.FirstOrDefault(astNode => Ast.Node.Type.TEXT_NODE.Equals(astNode.type)) == null)
            throw createNodeWasNotEmptyException(node);
    }

    private void assertNoParameters(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeContainedAParameterException)
    {
        assertNoNodeOfType(Ast.Node.Type.PARAMETER_NODE, node, createNodeContainedAParameterException);
    }

    private void assertNoOptionals(Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createNodeContainedAnOptionalException)
    {
        assertNoNodeOfType(Ast.Node.Type.OPTIONAL_NODE, node, createNodeContainedAnOptionalException);
    }

    private void assertNoNodeOfType(Ast.Node.Type nodeType, Ast.Node node,
            Func<Ast.Node, CucumberExpressionException> createException)
    {
        var faultyNode = node.nodes.FirstOrDefault(astNode => nodeType.Equals(astNode.type));
        if (faultyNode != null)
            throw createException(faultyNode);
    }

/*    public List<Argument> match(String text, Type...typeHints)
    {
        final Group group = treeRegexp.match(text);
        if (group == null)
        {
            return null;
        }

        List < ParameterType <?>> parameterTypes = new ArrayList<>(this.parameterTypes);
        for (int i = 0; i < parameterTypes.size(); i++)
        {
            ParameterType <?> parameterType = parameterTypes.get(i);
            Type type = i < typeHints.length ? typeHints[i] : String.class;
            if (parameterType.isAnonymous()) {
                ParameterByTypeTransformer defaultTransformer = parameterTypeRegistry.getDefaultParameterTransformer();
    parameterTypes.set(i, parameterType.deAnonymize(type, arg => defaultTransformer.transform(arg, type)));
            }
        }

        return Argument.build(group, parameterTypes);
    }*/

    public String getSource()
    {
        return source;
    }

    public Regex getRegexp()
    {
        return treeRegexp.pattern;
    }
}
