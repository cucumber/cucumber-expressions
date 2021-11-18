using System.Collections.Generic;

namespace CucumberExpressions;

public interface IParameterTypeRegistry
{
    IParameterType LookupByTypeName(string name);
    IEnumerable<IParameterType> GetParameterTypes();
}