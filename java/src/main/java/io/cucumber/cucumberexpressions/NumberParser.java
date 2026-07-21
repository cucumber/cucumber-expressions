package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.NumberParser.Parser.DecimalFormatParser;
import io.cucumber.cucumberexpressions.NumberParser.Parser.FallbackParser;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.util.Locale;

final class NumberParser {
    private final Parser delegate;

    NumberParser(Locale locale) {
        var numberFormat = DecimalFormat.getNumberInstance(locale);
        if (numberFormat instanceof DecimalFormat decimalFormat) {
            decimalFormat.setParseBigDecimal(true);
            var symbols = KeyboardFriendlyDecimalFormatSymbols.getInstance(locale);
            decimalFormat.setDecimalFormatSymbols(symbols);
            delegate = new DecimalFormatParser(numberFormat);
        } else {
            delegate = new FallbackParser();
        }
    }

    double parseDouble(String s) {
        return delegate.parseDouble(s);
    }

    float parseFloat(String s) {
        return delegate.parseFloat(s);
    }

    BigDecimal parseBigDecimal(String s) {
        return delegate.parseBigDecimal(s);
    }

    interface Parser {
        double parseDouble(String s);

        float parseFloat(String s);

        BigDecimal parseBigDecimal(String s);

        record DecimalFormatParser(NumberFormat numberFormat) implements Parser {

            @Override
            public double parseDouble(String s) {
                return parse(s).doubleValue();
            }

            @Override
            public float parseFloat(String s) {
                return parse(s).floatValue();
            }

            @Override
            public BigDecimal parseBigDecimal(String s) {
                return (BigDecimal) parse(s);
            }

            private Number parse(String s) {
                try {
                    return numberFormat.parse(s);
                } catch (ParseException e) {
                    throw new CucumberExpressionException("Failed to parse number", e);
                }
            }
        }

        // The locale did not have a DecimalFormat, so we could not
        // ask it to parse decimal numbers. Fall back to the default
        // number parsing.
        class FallbackParser implements Parser {
            @Override
            public double parseDouble(String s) {
                return Double.parseDouble(s);
            }

            @Override
            public float parseFloat(String s) {
                return Float.parseFloat(s);
            }

            @Override
            public BigDecimal parseBigDecimal(String s) {
                return new BigDecimal(s);
            }
        }
    }
}
