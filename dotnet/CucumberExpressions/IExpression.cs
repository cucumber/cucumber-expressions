using System;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public interface IExpression
{
    string Source { get; }
    Regex Regex { get; }
}
