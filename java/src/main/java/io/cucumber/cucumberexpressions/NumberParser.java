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
        numberFormat = DecimalFormat.getNumberInstance(locale);
        String exponentSeparator = "E";
        if (numberFormat instanceof DecimalFormat decimalFormat) {
            decimalFormat.setParseBigDecimal(true);
            DecimalFormatSymbols symbols = KeyboardFriendlyDecimalFormatSymbols.getInstance(locale);
            decimalFormat.setDecimalFormatSymbols(symbols);
            exponentSeparator = symbols.getExponentSeparator();
        }
        this.exponentSeparator = exponentSeparator;
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
        return new BigDecimal(removeExponentPlusSign(s));
    }

    private Number parse(String s) {
        try {
            return numberFormat.parse(removeExponentPlusSign(s));
        } catch (ParseException e) {
            throw new CucumberExpressionException("Failed to parse number", e);
        }
    }

    private String removeExponentPlusSign(String s) {
        String exponentPlus = exponentSeparator + "+";
        int index = s.indexOf(exponentPlus);
        if (index < 0) {
            return s;
        }
        return s.substring(0, index + exponentSeparator.length())
                + s.substring(index + exponentPlus.length());
    }
}
