using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions;

public class GeneratedExpression {
    //private static final Collator ENGLISH_COLLATOR = Collator.getInstance(Locale.ENGLISH);
    private static String[] JAVA_KEYWORDS = {
            "abstract", "assert", "boolean", "break", "byte", "case",
            "catch", "char", "class", "const", "continue",
            "default", "do", "double", "else", "extends",
            "false", "final", "finally", "float", "for",
            "goto", "if", "implements", "import", "instanceof",
            "int", "interface", "long", "native", "new",
            "null", "package", "private", "protected", "public",
            "return", "short", "static", "strictfp", "super",
            "switch", "synchronized", "this", "throw", "throws",
            "transient", "true", "try", "void", "volatile",
            "while"
    };
    private readonly String expressionTemplate;
    private readonly List<IParameterType> parameterTypes;

    public GeneratedExpression(String expressionTemplate, List<IParameterType> parameterTypes) {
        this.expressionTemplate = expressionTemplate;
        this.parameterTypes = parameterTypes;
    }

    private static bool isJavaKeyword(String keyword)
    {
        return JAVA_KEYWORDS.Contains(keyword);
    }

    public String getSource() {
        var parameterTypeNames = new List<string>();
        foreach (var parameterType in parameterTypes) {
            String name = parameterType.getName();
            parameterTypeNames.Add(name);
        }
        return String.Format(expressionTemplate, parameterTypeNames.Cast<object>().ToArray());
    }

    private String getParameterName(String typeName, Dictionary<String, int> usageByTypeName)
    {
        if (usageByTypeName.TryGetValue(typeName, out var count))
            count++;
        else
            count = 1;
        usageByTypeName[typeName] = count;

        return count == 1 && !isJavaKeyword(typeName) ? typeName : typeName + count;
    }

    public List<String> getParameterNames() {
        var usageByTypeName = new Dictionary<string, int>();
        var list = new List<string>();
        foreach (var parameterType in parameterTypes) {
            String parameterName = getParameterName(parameterType.getName(), usageByTypeName);
            list.Add(parameterName);
        }
        return list;
    }

    public List<IParameterType> getParameterTypes() {
        return parameterTypes;
    }
}
