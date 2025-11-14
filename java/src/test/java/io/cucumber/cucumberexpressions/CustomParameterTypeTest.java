package io.cucumber.cucumberexpressions;

import org.assertj.core.api.AbstractObjectAssert;
import org.assertj.core.api.InstanceOfAssertFactories;
import org.jspecify.annotations.Nullable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;

import static java.lang.Integer.parseInt;
import static java.util.Arrays.asList;
import static java.util.Objects.requireNonNull;
import static java.util.regex.Pattern.compile;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CustomParameterTypeTest {

    private ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    @BeforeEach
    @SuppressWarnings("TrailingComment")
    void create_parameter() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "color",                                              // name
                "red|blue|yellow",                                          // regexp
                Color.class,                                                // type
                (@Nullable String name) -> new Color(requireNonNull(name)), // transform
                false,                                                      // useForSnippets
                false                                                       // preferForRegexpMatch
        ));
    }

    @Test
    void throws_exception_for_illegal_character_in_parameter_name() {
        Executable testMethod = () -> new ParameterType<>(
                "(string)",
                ".*",
                String.class,
                (@Nullable String s) -> s,
                false,
                false
        );

        var exception = assertThrows(CucumberExpressionException.class, testMethod);
        assertThat(exception).hasMessage("Illegal character in parameter name {(string)}. Parameter names may not contain '{', '}', '(', ')', '\\' or '/'");
    }

    @Test
    void matches_CucumberExpression_parameters_with_custom_parameter_type() {
        var expression = new CucumberExpression("I have a {color} ball", parameterTypeRegistry);
        var arguments = expression.match("I have a red ball");
        asserThatSingleArgumentValue(arguments).isEqualTo(new Color("red"));
    }

    @Test
    void matches_CucumberExpression_parameters_with_multiple_capture_groups() {
        parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "coordinate",
                "(\\d+),\\s*(\\d+),\\s*(\\d+)",
                Coordinate.class,
                (@Nullable String[] args) -> new Coordinate(parseInt(requireNonNull(args[0])), parseInt(requireNonNull(args[1])), parseInt(requireNonNull(args[2]))),
                false,
                false
        ));
        var expression = new CucumberExpression("A {int} thick line from {coordinate} to {coordinate}", parameterTypeRegistry);
        var arguments = expression.match("A 5 thick line from 10,20,30 to 40,50,60");

        assertThat(arguments)
                .get()
                .asInstanceOf(InstanceOfAssertFactories.LIST)
                .map(Argument.class::cast)
                .extracting(Argument::getValue)
                .containsExactly(
                        5,
                        new Coordinate(10, 20, 30),
                        new Coordinate(40, 50, 60)
                );
    }

    @Test
    void warns_when_CucumberExpression_parameters_with_multiple_capture_groups_has_a_transformer() {
        parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "coordinate",
                "(\\d+),\\s*(\\d+),\\s*(\\d+)",
                Coordinate.class,
                (@Nullable String arg) -> {
                    throw new IllegalStateException();
                },
                false,
                false
        ));
        var expression = new CucumberExpression("A {int} thick line from {coordinate} to {coordinate}", parameterTypeRegistry);
        var arguments = expression.match("A 5 thick line from 10,20,30 to 40,50,60");

        assertDoesNotThrow(() -> getArgumentValue(arguments, 0));
        var exception = assertThrows(CucumberExpressionException.class, () -> getArgumentValue(arguments, 1));
        assertThat(exception).hasMessage(
                "ParameterType {coordinate} was registered with a Transformer but has multiple capture groups [(\\d+),\\s*(\\d+),\\s*(\\d+)]. " +
                        "Did you mean to use a CaptureGroupTransformer?"
        );
    }

    @Test
    void warns_when_anonymous_parameter_has_multiple_capture_groups() {
        parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        Expression expression = new RegularExpression(Pattern.compile("^A (\\d+) thick line from ((\\d+),\\s*(\\d+),\\s*(\\d+)) to ((\\d+),\\s*(\\d+),\\s*(\\d+))$"), parameterTypeRegistry);
        var arguments = expression.match("A 5 thick line from 10,20,30 to 40,50,60",
                Integer.class, Coordinate.class, Coordinate.class);

        assertNotNull(arguments);
        assertDoesNotThrow(() -> getArgumentValue(arguments, 0));

        var exception = assertThrows(CucumberExpressionException.class, () -> getArgumentValue(arguments, 1));
        assertThat(exception).hasMessage(
                "Anonymous ParameterType has multiple capture groups [(\\d+),\\s*(\\d+),\\s*(\\d+)]. " +
                        "You can only use a single capture group in an anonymous ParameterType."
        );
    }

    @Test
    void matches_CucumberExpression_parameters_with_custom_parameter_type_using_optional_group() {
        parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "color",
                asList("red|blue|yellow", "(?:dark|light) (?:red|blue|yellow)"),
                Color.class,
                (@Nullable String name) -> new Color(requireNonNull(name)),
                false,
                false
        ));
        var expression = new CucumberExpression("I have a {color} ball", parameterTypeRegistry);
        var match = expression.match("I have a dark red ball");

        asserThatSingleArgumentValue(match).isEqualTo(new Color("dark red"));
    }

    @Test
    void defers_transformation_until_queried_from_argument() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "throwing",
                "bad",
                CssColor.class,
                (@Nullable String arg) -> {
                    throw new RuntimeException(String.format("Can't transform [%s]", arg));
                },
                false,
                false
        ));
        var expression = new CucumberExpression("I have a {throwing} parameter", parameterTypeRegistry);
        var arguments = expression.match("I have a bad parameter");

        var exception = assertThrows(RuntimeException.class, () -> getArgumentValue(arguments, 0));
        assertThat(exception).hasMessage("ParameterType {throwing} failed to transform [bad] to " + CssColor.class, exception.getMessage());
    }

    @Test
    void conflicting_parameter_type_is_detected_for_type_name() {
        var exception = assertThrows(DuplicateTypeNameException.class, () ->
                parameterTypeRegistry.defineParameterType(new ParameterType<>(
                        "color",
                        ".*",
                        CssColor.class,
                        (@Nullable String name) -> new CssColor(requireNonNull(name)),
                        false,
                        false
                )));

        assertThat(exception).hasMessage("There is already a parameter type with name color");
    }

    @Test
    void conflicting_parameter_type_is_not_detected_for_type() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "whatever",
                ".*",
                Color.class,
                (@Nullable String name) -> new Color(requireNonNull(name)),
                false,
                false
        ));
    }

    @Test
    void conflicting_parameter_type_is_not_detected_for_regexp() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "css-color",
                "red|blue|yellow",
                CssColor.class,
                (@Nullable String name) -> new CssColor(requireNonNull(name)),
                false,
                false
        ));

        var cssColorArguments = new CucumberExpression("I have a {css-color} ball", parameterTypeRegistry).match("I have a blue ball");
        asserThatSingleArgumentValue(cssColorArguments).isEqualTo(new CssColor("blue"));
        
        var colorArguments = new CucumberExpression("I have a {color} ball", parameterTypeRegistry).match("I have a blue ball");
        asserThatSingleArgumentValue(colorArguments).isEqualTo(new Color("blue"));
        
    }

    @Test
    void matches_RegularExpression_arguments_with_custom_parameter_type_without_name() {
        parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "null",
                "red|blue|yellow",
                Color.class,
                (@Nullable String name) -> new Color(requireNonNull(name)),
                false,
                false
        ));

        var expression = new RegularExpression(compile("I have a (red|blue|yellow) ball"), parameterTypeRegistry);
        var arguments = expression.match("I have a red ball");
        asserThatSingleArgumentValue(arguments).isEqualTo(new Color("red"));
    }

    @SuppressWarnings("OptionalUsedAsFieldOrParameterType")
    private static void getArgumentValue(Optional<List<Argument<?>>> match, int index) {
        match.ifPresent(arguments -> arguments.get(index).getValue());
    }
    
    @SuppressWarnings("OptionalUsedAsFieldOrParameterType")
    private static AbstractObjectAssert<?, Object> asserThatSingleArgumentValue(Optional<List<Argument<?>>> match) {
        return assertThat(match).get()
                .asInstanceOf(InstanceOfAssertFactories.LIST)
                .map(Argument.class::cast)
                .singleElement()
                .extracting(Argument::getValue);
    }

    private record Coordinate(int x, int y, int z) {

    }

    record Color(String name) {

    }

    record CssColor(String name) {

    }

}
