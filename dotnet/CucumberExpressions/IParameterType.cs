using System;

namespace CucumberExpressions;

public interface IParameterType
{
    string[] Regexps { get; }
    string Name { get; }
    Type ParameterType { get; }
    int Weight { get; }
    bool UseForSnippets { get; }
}