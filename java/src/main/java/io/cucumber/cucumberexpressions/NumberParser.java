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

    /**
     * Removes the {@code +} from a positive exponent, if present.
     * <p>
     * {@link DecimalFormat} stops parsing when it reaches an explicit {@code +}
     * in the exponent and silently returns what it has read so far, so
     * {@code 1.5E+3} parses as {@code 1.5} rather than failing. It handles the
     * exponent correctly without the sign, and {@code E3} means the same as
     * {@code E+3}, so dropping the sign is enough.
     * <p>
     * Doing it this way rather than delegating to {@link Double#valueOf} keeps
     * parsing locale aware, and keeps {@code {bigdecimal}} exact.
     */
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
