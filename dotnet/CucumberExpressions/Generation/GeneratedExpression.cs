using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions.Generation;

public class GeneratedExpression
{
    #region Keywords
    private static readonly string[] CSharpKeywords =
    {
        "abstract",
        "as",
        "base",
        "bool",
        "break",
        "byte",
        "case",
        "catch",
        "char",
        "checked",
        "class",
        "const",
        "continue",
        "decimal",
        "default",
        "delegate",
        "do",
        "double",
        "else",
        "enum",
        "event",
        "explicit",
        "extern",
        "false",
        "finally",
        "fixed",
        "float",
        "for",
        "foreach",
        "goto",
        "if",
        "implicit",
        "in",
        "int",
        "interface",
        "internal",
        "is",
        "lock",
        "long",
        "namespace",
        "new",
        "null",
        "object",
        "operator",
        "out",
        "override",
        "params",
        "private",
        "protected",
        "public",
        "readonly",
        "ref",
        "return",
        "sbyte",
        "sealed",
        "short",
        "sizeof",
        "stackalloc",
        "static",
        "string",
        "struct",
        "switch",
        "this",
        "throw",
        "true",
        "try",
        "typeof",
        "uint",
        "ulong",
        "unchecked",
        "unsafe",
        "ushort",
        "using",
        "virtual",
        "void",
        "volatile",
        "while"
    };
    #endregion
    private readonly string _expressionTemplate;
    private readonly IParameterType[] _parameterTypes;

    public GeneratedExpression(string expressionTemplate, IParameterType[] parameterTypes)
    {
        _expressionTemplate = expressionTemplate;
        _parameterTypes = parameterTypes;
    }

    private static bool IsCSharpKeyword(string keyword)
    {
        return CSharpKeywords.Contains(keyword);
    }

    public string GetSource()
    {
        var parameterTypeNames = new List<string>();
        foreach (var parameterType in _parameterTypes)
        {
            string name = parameterType.Name;
            parameterTypeNames.Add(name);
        }
        return string.Format(_expressionTemplate, parameterTypeNames.Cast<object>().ToArray());
    }

    private string GetParameterName(string typeName, Dictionary<string, int> usageByTypeName)
    {
        if (usageByTypeName.TryGetValue(typeName, out var count))
            count++;
        else
            count = 1;
        usageByTypeName[typeName] = count;

        return count == 1 && !IsCSharpKeyword(typeName) ? typeName : typeName + count;
    }

    public List<string> GetParameterNames()
    {
        var usageByTypeName = new Dictionary<string, int>();
        var list = new List<string>();
        foreach (var parameterType in _parameterTypes)
        {
            string parameterName = GetParameterName(parameterType.Name, usageByTypeName);
            list.Add(parameterName);
        }
        return list;
    }

    public IParameterType[] GetParameterTypes()
    {
        return _parameterTypes;
    }
}
