package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.util.Locale;

import static io.cucumber.cucumberexpressions.Assertions.asserThatSingleArgumentValue;

class EnumParameterTypeTest {

    public enum Mood {
        happy,
        meh,
        sad
    }

    @Test
    void converts_to_enum() {
        var registry = new ParameterTypeRegistry(Locale.ENGLISH);
        registry.defineParameterType(ParameterType.fromEnum(Mood.class));

        var expression = new CucumberExpression("I am {Mood}", registry);
        var args = expression.match("I am happy");
        asserThatSingleArgumentValue(args).isEqualTo(Mood.happy);
    }
}
