package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Locale;

import static java.util.Collections.singletonList;
import static java.util.Objects.requireNonNull;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class ArgumentTest {
    @Test
    public void exposes_parameter_type() {
        TreeRegexp treeRegexp = new TreeRegexp("three (.*) mice");
        Group group = requireNonNull(treeRegexp.match("three blind mice"));
        
        ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        List<ParameterType<?>> parameterTypes = singletonList(parameterTypeRegistry.lookupByTypeName("string"));
        
        List<Argument<?>> arguments = Argument.build(group, parameterTypes);
        Argument<?> argument = arguments.get(0);
        assertEquals("string", argument.getParameterType().getName());
    }

}
