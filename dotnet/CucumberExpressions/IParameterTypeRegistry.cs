using System.Collections.Generic;

namespace CucumberExpressions;

public interface IParameterTypeRegistry
{
    IParameterType lookupByTypeName(string name);
    IEnumerable<IParameterType> getParameterTypes();
}