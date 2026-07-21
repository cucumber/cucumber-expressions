using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Numerics;

namespace CucumberExpressions;

public class ParameterTypeRegistry : IParameterTypeRegistry
{
    private readonly Dictionary<string, IParameterType> _parameterTypesByName = new();
    private readonly List<IParameterType> _parameterTypes = new();
    private readonly CultureInfo _cultureInfo;

    public ParameterTypeRegistry()
        : this(CultureInfo.InvariantCulture)
    {
    }

    public ParameterTypeRegistry(CultureInfo cultureInfo)
    {
        _cultureInfo = cultureInfo ?? throw new ArgumentNullException(nameof(cultureInfo));
        foreach (var parameterType in CreateDefaultParameterTypes())
            DefineParameterType(parameterType);
    }

    public IParameterType LookupByTypeName(string name)
        => _parameterTypesByName.TryGetValue(name, out var parameterType) ? parameterType : null;

    public IEnumerable<IParameterType> GetParameterTypes() => _parameterTypes;

    public void DefineParameterType(IParameterType parameterType)
    {
        if (parameterType == null) throw new ArgumentNullException(nameof(parameterType));

        if (parameterType.Name != null)
        {
            if (_parameterTypesByName.ContainsKey(parameterType.Name))
                throw new CucumberExpressionException(parameterType.Name.Length == 0
                    ? "The anonymous parameter type has already been defined"
                    : $"There is already a parameter type with name {parameterType.Name}");

            _parameterTypesByName.Add(parameterType.Name, parameterType);
        }

        _parameterTypes.Add(parameterType);
    }

    private IEnumerable<IParameterType> CreateDefaultParameterTypes()
    {
        var floatRegexps = new[] { ParameterTypeConstants.GetFloatParameterRegex(_cultureInfo) };
        var integerRegexps = new[] { ParameterTypeConstants.IntParameterRegex, "\\d+" };

        yield return new ParameterType<int>(
            ParameterTypeConstants.IntParameterName,
            integerRegexps,
            groupValues => int.Parse(groupValues[0], NumberStyles.Integer, _cultureInfo),
            true, 1000);

        yield return new ParameterType<float>(
            ParameterTypeConstants.FloatParameterName,
            floatRegexps,
            groupValues => float.Parse(RemoveExponentPlusSign(groupValues[0]), NumberStyles.Float | NumberStyles.AllowThousands, _cultureInfo),
            false);

        yield return new ParameterType<string>(
            ParameterTypeConstants.WordParameterName,
            ParameterTypeConstants.WordParameterRegexps,
            groupValues => groupValues[0],
            false);

        yield return new ParameterType<string>(
            ParameterTypeConstants.StringParameterName,
            ParameterTypeConstants.StringParameterRegexps,
            groupValues => UnescapeQuotes(groupValues[0]));

        yield return new ParameterType<string>(
            "",
            new[] { ParameterTypeConstants.AnonymousParameterRegex },
            groupValues => groupValues[0],
            false);

        yield return new ParameterType<double>(
            ParameterTypeConstants.DoubleParameterName,
            floatRegexps,
            groupValues => double.Parse(RemoveExponentPlusSign(groupValues[0]), NumberStyles.Float | NumberStyles.AllowThousands, _cultureInfo));

        yield return new ParameterType<string>(
            "bigdecimal",
            floatRegexps,
            groupValues => groupValues[0],
            false);

        yield return new ParameterType<byte>(
            "byte",
            integerRegexps,
            groupValues => byte.Parse(groupValues[0], NumberStyles.Integer, _cultureInfo),
            false);

        yield return new ParameterType<short>(
            "short",
            integerRegexps,
            groupValues => short.Parse(groupValues[0], NumberStyles.Integer, _cultureInfo),
            false);

        yield return new ParameterType<long>(
            "long",
            integerRegexps,
            groupValues => long.Parse(groupValues[0], NumberStyles.Integer, _cultureInfo),
            false);

        yield return new ParameterType<BigInteger>(
            "biginteger",
            integerRegexps,
            groupValues => BigInteger.Parse(groupValues[0], NumberStyles.Integer, _cultureInfo),
            false);
    }

    private string RemoveExponentPlusSign(string value)
    {
        var index = value.IndexOf("E+", StringComparison.Ordinal);
        return index < 0 ? value : value.Substring(0, index + 1) + value.Substring(index + 2);
    }

    private static string UnescapeQuotes(string value)
    {
        if (value.Length < 2)
            return value;

        var quote = value[0];
        if ((quote != '"' && quote != '\'') || value[value.Length - 1] != quote)
            return value;

        return value.Substring(1, value.Length - 2).Replace("\\" + quote, quote.ToString());
    }
}
