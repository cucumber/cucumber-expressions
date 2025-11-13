package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;
import org.jspecify.annotations.Nullable;

import java.lang.reflect.Type;
import java.util.List;
import java.util.regex.Pattern;

@API(status = API.Status.STABLE)
public interface Expression {
    
    @Nullable List<Argument<?>> match(String text, Type... typeHints);

    Pattern getRegexp();

    String getSource();
}
