package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Locale;

import static java.util.Locale.forLanguageTag;
import static org.junit.jupiter.api.Assertions.assertEquals;

class NumberParserTest {

    private final NumberParser english = new NumberParser(Locale.ENGLISH);
    private final NumberParser german = new NumberParser(Locale.GERMAN);
    private final NumberParser canadianFrench = new NumberParser(Locale.CANADA_FRENCH);
    private final NumberParser norwegian = new NumberParser(forLanguageTag("no"));
    private final NumberParser canadian = new NumberParser(Locale.CANADA);

    @Test
    void can_parse_float() {
        assertEquals(1042.2f, english.parseFloat("1,042.2"), 0);
        assertEquals(1042.2f, canadian.parseFloat("1,042.2"), 0);

        assertEquals(1042.2f, german.parseFloat("1.042,2"), 0);
        assertEquals(1042.2f, canadianFrench.parseFloat("1.042,2"), 0);
        assertEquals(1042.2f, norwegian.parseFloat("1.042,2"), 0);
    }

    @Test
    void can_parse_double() {
        assertEquals(1042.000000000000002, english.parseDouble("1,042.000000000000002"), 0);
        assertEquals(1042.000000000000002, canadian.parseDouble("1,042.000000000000002"), 0);

        assertEquals(1042.000000000000002, german.parseDouble("1.042,000000000000002"), 0);
        assertEquals(1042.000000000000002, canadianFrench.parseDouble("1.042,000000000000002"), 0);
        assertEquals(1042.000000000000002, norwegian.parseDouble("1.042,000000000000002"), 0);
    }

    @Test
    void can_parse_big_decimals() {
        assertEquals(new BigDecimal("1042.0000000000000000000002"), english.parseBigDecimal("1,042.0000000000000000000002"));
        assertEquals(new BigDecimal("1042.0000000000000000000002"), canadian.parseBigDecimal("1,042.0000000000000000000002"));

        assertEquals(new BigDecimal("1042.0000000000000000000002"), german.parseBigDecimal("1.042,0000000000000000000002"));
        assertEquals(new BigDecimal("1042.0000000000000000000002"), canadianFrench.parseBigDecimal("1.042,0000000000000000000002"));
        assertEquals(new BigDecimal("1042.0000000000000000000002"), norwegian.parseBigDecimal("1.042,0000000000000000000002"));
    }

    @Test
    void can_parse_negative() {
        assertEquals(-1042.2f, english.parseFloat("-1,042.2"), 0);
        assertEquals(-1042.2f, canadian.parseFloat("-1,042.2"), 0);

        assertEquals(-1042.2f, german.parseFloat("-1.042,2"), 0);
        assertEquals(-1042.2f, canadianFrench.parseFloat("-1.042,2"), 0);
        assertEquals(-1042.2f, norwegian.parseFloat("-1.042,2"), 0);
    }

    @Test
    void can_parse_exponents() {
        assertEquals(new BigDecimal("100"), english.parseBigDecimal("1.00E2"));
        assertEquals(new BigDecimal("100"), canadian.parseBigDecimal("1.00e2"));
        assertEquals(new BigDecimal("100"), german.parseBigDecimal("1,00E2"));
        assertEquals(new BigDecimal("100"), canadianFrench.parseBigDecimal("1,00E2"));
        assertEquals(new BigDecimal("100"), norwegian.parseBigDecimal("1,00E2"));

        assertEquals(new BigDecimal("0.01"), english.parseBigDecimal("1E-2"));
        assertEquals(new BigDecimal("0.01"), canadian.parseBigDecimal("1e-2"));
        assertEquals(new BigDecimal("0.01"), german.parseBigDecimal("1E-2"));
        assertEquals(new BigDecimal("0.01"), canadianFrench.parseBigDecimal("1E-2"));
        assertEquals(new BigDecimal("0.01"), norwegian.parseBigDecimal("1E-2"));
    }

}
