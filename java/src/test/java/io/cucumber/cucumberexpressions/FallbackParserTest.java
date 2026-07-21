package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.NumberParser.FallbackParser;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class FallbackParserTest {

    final NumberParser fallback = new FallbackParser();

    @Test
    void can_parse_float() {
        assertEquals(1042.2f, fallback.parseFloat("1042.2"), 0);
    }

    @Test
    void can_parse_double() {
        assertEquals(Double.parseDouble("1042.000000000000002"), fallback.parseDouble("1042.000000000000002"), 0);
    }

    @Test
    void can_parse_big_decimals() {
        assertEquals(new BigDecimal("1042.0000000000000000000002"), fallback.parseBigDecimal("1042.0000000000000000000002"));
    }

    @Test
    void can_parse_negative() {
        assertEquals(-1042.2f, fallback.parseFloat("-1042.2"), 0);
    }

    @Test
    void can_parse_exponents() {
        assertEquals(new BigDecimal("100"), fallback.parseBigDecimal("1.00E2"));
        assertEquals(new BigDecimal("0.01"), fallback.parseBigDecimal("1E-2"));
    }

    @Test
    void can_parse_positive_exponents() {
        assertEquals(new BigDecimal("100"), fallback.parseBigDecimal("1.00E+2"));
        assertEquals(1500.0, fallback.parseDouble("1.5E+3"), 0);
        assertEquals(1500.0f, fallback.parseFloat("1.5E+3"), 0);
    }

    @Test
    void can_parse_leading_plus_sign() {
        assertEquals(new BigDecimal("1.5"), fallback.parseBigDecimal("+1.5"));
        assertEquals(1042.2f, fallback.parseFloat("+1042.2"), 0);
        // A leading plus sign combined with an exponent
        assertEquals(new BigDecimal("1.5E+3"), fallback.parseBigDecimal("+1.5E+3"));
        assertEquals(1500.0, fallback.parseDouble("+1.5E+3"), 0);
    }
}
