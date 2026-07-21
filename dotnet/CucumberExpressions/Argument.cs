using CucumberExpressions.Parsing;

namespace CucumberExpressions;

public class Argument
{
    public Group Group { get; }
    public IParameterType ParameterType { get; }

    public Argument(Group group, IParameterType parameterType)
    {
        Group = group;
        ParameterType = parameterType;
    }

    public object GetValue()
    {
        var groupValues = Group?.GetValues();
        if (ParameterType is IParameterTypeTransformer transformer)
            return transformer.Transform(groupValues);
        return groupValues == null ? null : groupValues[0];
    }
}
