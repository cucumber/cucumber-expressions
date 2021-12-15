using System;
using System.Linq;
using System.Text.RegularExpressions;

namespace CucumberExpressions.Generation;

internal class ParameterTypeMatcher : IComparable<ParameterTypeMatcher>
{
    private readonly Regex _regex;
    private readonly string _text;
    private Match _match;

    public IParameterType ParameterType { get; }

    public ParameterTypeMatcher(IParameterType parameterType, Regex regex, string text)
    {
        ParameterType = parameterType;
        _regex = regex;
        _text = text;
    }

    private static bool IsWhitespaceOrPunctuationOrSymbol(char c)
    {
        return Regex.IsMatch(c.ToString(), "[\\p{Z}\\p{P}\\p{S}]");
    }

    public bool AdvanceToAndFind(int newMatchPos)
    {
        _match = _regex.Matches(_text, newMatchPos).OfType<Match>()
            .FirstOrDefault(m => m.Length > 0);

        if (_match != null && GroupHasWordBoundaryOnBothSides())
            return true;
        return false;
    }

    private bool GroupHasWordBoundaryOnBothSides()
    {
        return GroupHasLeftWordBoundary() && GroupHasRightWordBoundary();
    }

    private bool GroupHasLeftWordBoundary()
    {
        if (_match.Index > 0)
        {
            char before = _text[_match.Index - 1];
            return IsWhitespaceOrPunctuationOrSymbol(before);
        }
        return true;
    }

    private bool GroupHasRightWordBoundary()
    {
        var end = _match.Index + _match.Length;
        if (end < _text.Length)
        {
            char after = _text[end];
            return IsWhitespaceOrPunctuationOrSymbol(after);
        }
        return true;
    }

    public int GetMatchStart()
    {
        return _match.Index;
    }

    public string GetMatchValue()
    {
        return _match.Value;
    }

    public int CompareTo(ParameterTypeMatcher o)
    {
        int posComparison = GetMatchStart().CompareTo(o.GetMatchStart());
        if (posComparison != 0) return posComparison;
        int lengthComparison = o.GetMatchValue().Length.CompareTo(GetMatchValue().Length);
        if (lengthComparison != 0) return lengthComparison;
        int weightComparison = o.ParameterType.Weight.CompareTo(ParameterType.Weight);
        if (weightComparison != 0) return weightComparison;
        return 0;
    }
}
