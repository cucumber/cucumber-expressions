using System;
using System.Collections.Generic;

namespace CucumberExpressions;

public interface IParameterType
{
    string[] getRegexps();
    string getName();
    Type getType();
    int weight();
    bool useForSnippets();
}