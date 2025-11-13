package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.util.Locale;

import static org.assertj.core.api.Assertions.assertThat;

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
        assertThat(args).singleElement()
                .extracting(Argument::getValue)
                .isEqualTo(Mood.happy);
    }

}
