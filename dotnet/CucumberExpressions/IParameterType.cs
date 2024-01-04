using System;

namespace CucumberExpressions;

public interface IParameterType
{
    string[] RegexStrings { get; }
    string Name { get; }
    Type ParameterType { get; }
    int Weight { get; }
    bool UseForSnippets { get; }
}