using System;

namespace CucumberExpressions;

public class ParameterType<T> : IParameterType, IParameterTypeTransformer
{
    private readonly Func<string[], T> _transformer;

    public string Name { get; }
    public string[] RegexStrings { get; }
    public Type Type => typeof(T);

    Type IParameterType.ParameterType => typeof(T);
    public int Weight { get; }
    public bool UseForSnippets { get; }

    public ParameterType(
        string name,
        string[] regexStrings,
        Func<string[], T> transformer,
        bool useForSnippets = true,
        int weight = 0)
    {
        if (regexStrings == null || regexStrings.Length == 0)
            throw new ArgumentException("regexStrings must not be empty", nameof(regexStrings));

        Name = name;
        RegexStrings = regexStrings;
        _transformer = transformer ?? throw new ArgumentNullException(nameof(transformer));
        UseForSnippets = useForSnippets;
        Weight = weight;
    }

    public ParameterType(
        string name,
        string regexString,
        Func<string, T> transformer,
        bool useForSnippets = true,
        int weight = 0)
        : this(name, new[] { regexString }, groupValues => transformer(groupValues[0]), useForSnippets, weight)
    {
    }

    public object Transform(string[] groupValues) => _transformer(groupValues);
}
