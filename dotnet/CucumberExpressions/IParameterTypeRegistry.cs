namespace CucumberExpressions;

public interface IParameterTypeRegistry
{
    IParameterType lookupByTypeName(string name);
}