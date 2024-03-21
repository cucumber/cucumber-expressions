package io.cucumber.cucumberexpressions;

import java.text.DecimalFormatSymbols;
import java.util.Locale;

/**
 * A set of localized decimal symbols that can be written on a regular keyboard.
 * <p>
 * Note quite complete, feel free to make a suggestion.
 */
class KeyboardFriendlyDecimalFormatSymbols {

    static DecimalFormatSymbols getInstance(Locale locale) {
        DecimalFormatSymbols symbols = DecimalFormatSymbols.getInstance(locale);

        // Replace the minus sign with minus-hyphen as available on most keyboards.
        if (symbols.getMinusSign() == '\u2212') {
            symbols.setMinusSign('-');
        }

        if (symbols.getDecimalSeparator() == '.') {
            // For locales that use the period as the decimal separator
            // always use the comma for thousands. The alternatives are
            // not available on a keyboard
            symbols.setGroupingSeparator(',');
        } else if (symbols.getDecimalSeparator() == ',') {
            // For locales that use the comma as the decimal separator
            // always use the period for thousands. The alternatives are
            // not available on a keyboard
            symbols.setGroupingSeparator('.');
        }
        return symbols;
    }
}
