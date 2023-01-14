package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RegexpUtilsTest {

    @Test
    void escape_all_regexp_characters() {
        assertEquals("\\^\\$\\[\\]\\(\\)\\{\\}\\.\\|\\?\\*\\+\\\\", RegexpUtils.escapeRegex("^$[](){}.|?*+\\"));
    }

    @Test
    void escape_escaped_regexp_characters() {
        assertEquals("\\^\\$\\[\\]\\\\\\(\\\\\\)\\{\\}\\\\\\\\\\.\\|\\?\\*\\+", RegexpUtils.escapeRegex("^$[]\\(\\){}\\\\.|?*+"));
    }


    @Test
    void do_not_escape_when_there_is_nothing_to_escape() {
        assertEquals("dummy", RegexpUtils.escapeRegex("dummy"));
    }

    @Test
    void escapeRegex_gives_no_error_for_unicode_characters() {
        assertEquals("🥒", RegexpUtils.escapeRegex("🥒"));
    }

}
