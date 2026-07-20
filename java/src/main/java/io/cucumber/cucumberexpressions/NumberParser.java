package io.cucumber.cucumberexpressions;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.NumberFormat;
import java.text.ParseException;
import java.util.Locale;

final class NumberParser {
    private final NumberFormat numberFormat;
    private final String exponentSeparator;

    NumberParser(Locale locale) {
        DecimalFormatSymbols symbols = KeyboardFriendlyDecimalFormatSymbols.getInstance(locale);
        this.exponentSeparator = symbols.getExponentSeparator();
        this.numberFormat = DecimalFormat.getNumberInstance(locale);
        if (numberFormat instanceof DecimalFormat decimalFormat) {
            decimalFormat.setParseBigDecimal(true);
            decimalFormat.setDecimalFormatSymbols(symbols);
        }
    }

    double parseDouble(String s) {
        return parse(s).doubleValue();
    }

    float parseFloat(String s) {
        return parse(s).floatValue();
    }

    BigDecimal parseBigDecimal(String s) {
        if (numberFormat instanceof DecimalFormat) {
            return (BigDecimal) parse(s);
        }
        // Fall back to default big decimal format
        // if the locale does not have a DecimalFormat
        return new BigDecimal(s);
    }

    private Number parse(String s) {
        int index = s.indexOf(exponentSeparator);
        if (index < 0) {
            return parseSignificand(s);
        }
        // DecimalFormat silently ignores a '+' in the exponent, and everything
        // that follows it. So parse the exponent ourselves and scale accordingly.
        BigDecimal significand = toBigDecimal(parseSignificand(s.substring(0, index)));
        return significand.scaleByPowerOfTen(parseExponent(s.substring(index + exponentSeparator.length())));
    }

    private Number parseSignificand(String s) {
        // DecimalFormat has no positive prefix, so it can not parse a leading
        // '+'. It does not change the value, so drop it.
        String significand = s.startsWith("+") ? s.substring(1) : s;
        try {
            return numberFormat.parse(significand);
        } catch (ParseException e) {
            throw new CucumberExpressionException("Failed to parse number", e);
        }
    }

    private static int parseExponent(String s) {
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            throw new CucumberExpressionException("Failed to parse number", e);
        }
    }

    private static BigDecimal toBigDecimal(Number number) {
        if (number instanceof BigDecimal bigDecimal) {
            return bigDecimal;
        }
        // The locale did not have a DecimalFormat, so we could not
        // ask it to parse into a BigDecimal.
        return new BigDecimal(number.toString());
    }
}
