package io.cucumber.cucumberexpressions;

import org.assertj.core.api.AbstractObjectAssert;
import org.assertj.core.api.InstanceOfAssertFactories;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

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
        asserThatSingleArgumentValue(args).isEqualTo(Mood.happy);
    }
    
        @SuppressWarnings("OptionalUsedAsFieldOrParameterType")
    private static AbstractObjectAssert<?, Object> asserThatSingleArgumentValue(Optional<List<Argument<?>>> match) {
        return assertThat(match).get()
                .asInstanceOf(InstanceOfAssertFactories.LIST)
                .map(Argument.class::cast)
                .singleElement()
                .extracting(Argument::getValue);
    }

}
