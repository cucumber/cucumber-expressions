package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import static io.cucumber.cucumberexpressions.RegexpUtils.escapeRegex;
import static org.junit.jupiter.api.Assertions.assertEquals;

class RegexpUtilsTest {

    @Test
    void escape_regex_characters(){
        assertEquals("hello \\$world", escapeRegex("hello $world"));
    }

    @Test
    void escape_all_regexp_characters() {
        assertEquals("\\^\\$\\[\\]\\(\\)\\{\\}\\.\\|\\?\\*\\+\\\\", escapeRegex("^$[](){}.|?*+\\"));
    }

    @Test
    void escape_escaped_regexp_characters() {
        assertEquals("\\^\\$\\[\\]\\\\\\(\\\\\\)\\{\\}\\\\\\\\\\.\\|\\?\\*\\+", escapeRegex("^$[]\\(\\){}\\\\.|?*+"));
    }


    @Test
    void do_not_escape_when_there_is_nothing_to_escape() {
        assertEquals("hello world", escapeRegex("hello world"));
    }

    @Test
    void gives_no_error_for_unicode_characters() {
        assertEquals("🥒", escapeRegex("🥒"));
    }

}
