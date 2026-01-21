package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class GroupTest {

    @Test
    void parse(){
        List<Group> groups = (List<Group>) Group.parse(Pattern.compile("a(bc)?(d(e)?)"));
        assertEquals("bc", groups.get(0).getValue());
        assertFalse(groups.get(0).getChildren().isPresent());
        assertEquals("d(e)?", groups.get(1).getValue());
        assertEquals("e", groups.get(1).getChildren().get().get(0).getValue());
        assertFalse(groups.get(1).getChildren().get().get(0).getChildren().isPresent());
    }
}
