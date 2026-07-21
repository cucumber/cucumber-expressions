namespace CucumberExpressions;

public interface IParameterTypeTransformer
{
    object Transform(string[] groupValues);
}
