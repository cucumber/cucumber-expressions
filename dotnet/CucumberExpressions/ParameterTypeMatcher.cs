using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

class ParameterTypeMatcher : IComparable<ParameterTypeMatcher>
{
    private readonly IParameterType parameterType;
    private readonly Regex matcher;
    private readonly String text;
    private Match _match;

    public ParameterTypeMatcher(IParameterType parameterType, Regex matcher, String text) {
        this.parameterType = parameterType;
        this.matcher = matcher;
        this.text = text;
    }

    private static bool isWhitespaceOrPunctuationOrSymbol(char c)
    {
        return Regex.IsMatch(c.ToString(), "[\\p{Z}\\p{P}\\p{S}]");
    }

    public bool advanceToAndFind(int newMatchPos)
    {
        _match = matcher.Matches(text, newMatchPos).OfType<Match>()
            .FirstOrDefault(m => m.Length > 0);

        if (_match != null && groupHasWordBoundaryOnBothSides())
            return true;
        return false;
    }

    private bool groupHasWordBoundaryOnBothSides() {
        return groupHasLeftWordBoundary() && groupHasRightWordBoundary();
    }

    private bool groupHasLeftWordBoundary() {
        if (_match.Index > 0) {
            char before = text[_match.Index - 1];
            return isWhitespaceOrPunctuationOrSymbol(before);
        }
        return true;
    }

    private bool groupHasRightWordBoundary()
    {
        var end = _match.Index + _match.Length;
        if (end < text.Length) {
            char after = text[end];
            return isWhitespaceOrPunctuationOrSymbol(after);
        }
        return true;
    }

    public int start() {
        return _match.Index;
    }

    public String group() {
        return _match.Value;
    }

    public int CompareTo(ParameterTypeMatcher o)
    {
        int posComparison = start().CompareTo(o.start());
        if (posComparison != 0) return posComparison;
        int lengthComparison = o.group().Length.CompareTo(group().Length);
        if (lengthComparison != 0) return lengthComparison;
        int weightComparison = o.parameterType.weight().CompareTo(parameterType.weight());
        if (weightComparison != 0) return weightComparison;
        return 0;
    }

    public IParameterType getParameterType() {
        return parameterType;
    }

    public String toString() {
        return parameterType.getType().ToString();
    }
}
