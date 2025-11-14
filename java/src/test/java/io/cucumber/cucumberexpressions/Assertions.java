package io.cucumber.cucumberexpressions;

import org.assertj.core.api.AbstractObjectAssert;
import org.assertj.core.api.InstanceOfAssertFactories;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

final class Assertions {
    
    private Assertions(){
        // utility class
    }

    @SuppressWarnings("OptionalUsedAsFieldOrParameterType")
    static AbstractObjectAssert<?, Object> asserThatSingleArgumentValue(Optional<List<Argument<?>>> match) {
        return assertThat(match).get()
                .asInstanceOf(InstanceOfAssertFactories.LIST)
                .map(Argument.class::cast)
                .singleElement()
                .extracting(Argument::getValue);
    }
}
