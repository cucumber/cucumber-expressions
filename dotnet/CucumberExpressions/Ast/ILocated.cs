namespace CucumberExpressions.Ast;

public interface ILocated
{
    int Start { get; }
    int End { get; }
}