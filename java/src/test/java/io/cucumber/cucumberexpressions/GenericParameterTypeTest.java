package io.cucumber.cucumberexpressions;

import org.assertj.core.api.AbstractObjectAssert;
import org.assertj.core.api.InstanceOfAssertFactories;
import org.jspecify.annotations.Nullable;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

import static java.util.Arrays.asList;
import static java.util.Collections.singletonList;
import static java.util.Objects.requireNonNull;
import static org.assertj.core.api.Assertions.assertThat;

public class GenericParameterTypeTest {

    @Test
    public void transforms_to_a_list_of_string() {
        ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "stringlist",
                singletonList(".*"),
                new TypeReference<List<String>>() {
                }.getType(),
                (@Nullable String arg) -> asList(requireNonNull(arg).split(",")),
                false,
                false)
        );
        var expression = new CucumberExpression("I have {stringlist} yay", parameterTypeRegistry);
        var args = expression.match("I have three,blind,mice yay");
        asserThatSingleArgumentValue(args).isEqualTo(asList("three", "blind", "mice"));
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
