using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class RegularExpression : IExpression
{
    public virtual Regex Regex { get; }

    public virtual string Source => Regex.ToString();

    public RegularExpression(Regex expressionRegexp)
    {
        Regex = expressionRegexp;
    }
}
