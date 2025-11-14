package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.lang.reflect.Type;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

@API(status = API.Status.STABLE)
public interface Expression {

    /**
     * Matches a string to an expression. Empty if no match.
     */
    Optional<List<Argument<?>>> match(String text, Type... typeHints);

    Pattern getRegexp();

    String getSource();
}
