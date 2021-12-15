using System.Globalization;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public static class ParameterTypeConstants
{
    public const string StringParameterName = "string";
    public const string StringParameterRegexDoubleQuote = "\"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"";
    public const string StringParameterRegexApostrophe = "'([^'\\\\]*(?:\\\\.[^'\\\\]*)*)'";
    public static readonly string[] StringParameterRegexps = { StringParameterRegexDoubleQuote, StringParameterRegexApostrophe };

    public const string IntParameterName = "int";
    public const string IntParameterRegex = "-?\\d+";
    public static readonly string[] IntParameterRegexps = { IntParameterRegex };

    public const string FloatParameterName = "float";
    public const string DoubleParameterName = "double";
    private const string FloatPartSign = "[-+]?";
    private const string FloatPartMustContainNumber = "(?=.*\\d.*)";
    private const string FloatPartScientificNumber = "(?:\\d+[{exponent}]-?\\d+)?";
    private const string FloatPartDecimalFraction = "(?:[{decimal}](?=\\d.*))?\\d*";
    private const string FloatPartInteger = "(?:\\d+(?:[{group}]?\\d+)*)*";
    public const string FloatParameterRegexTemplate = FloatPartMustContainNumber + FloatPartSign + FloatPartInteger + FloatPartDecimalFraction + FloatPartScientificNumber;
    public static readonly string FloatParameterRegex = GetGenericFloatParameterRegex();
    public static readonly string[] FloatParameterRegexps = { FloatParameterRegex };
    public static readonly string FloatParameterRegexEn = GetFloatParameterRegex(CultureInfo.InvariantCulture);
    public static readonly string[] FloatParameterRegexpsEn = { FloatParameterRegexEn };

    public const string WordParameterName = "Word";
    public const string WordParameterRegex = "[^\\s]+";
    public static readonly string[] WordParameterRegexps = { WordParameterRegex };

    public const string AnonymousParameterRegex = ".*";

    public static string GetFloatParameterRegex(CultureInfo cultureInfo)
    {
        return FloatParameterRegexTemplate
            .Replace("{decimal}", cultureInfo.NumberFormat.NumberDecimalSeparator)
            .Replace("{group}", cultureInfo.NumberFormat.NumberGroupSeparator)
            .Replace("{exponent}", "E"); // exponent separator
    }

    private static string GetGenericFloatParameterRegex()
    {
        var punctuation = "\\p{Pc}\\p{Po}";
        return FloatParameterRegexTemplate
            .Replace("{decimal}", punctuation)
            .Replace("{group}", punctuation + "\\p{Pd} ")
            .Replace("{exponent}", "E"); // exponent separator
    }
}