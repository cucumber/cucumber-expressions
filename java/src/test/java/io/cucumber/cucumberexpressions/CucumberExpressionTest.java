package io.cucumber.cucumberexpressions;

import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.api.function.Executable;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.junit.jupiter.params.converter.ConvertWith;
import org.junit.jupiter.params.provider.MethodSource;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.file.DirectoryStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Arrays.asList;
import static java.util.Collections.singletonList;
import static java.util.Objects.requireNonNull;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.core.Is.is;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

@NullMarked
class CucumberExpressionTest {
    private final ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        Path path = Paths.get("..", "testdata", "cucumber-expression", "matching");
        try (DirectoryStream<Path> directories = newDirectoryStream(path)) {
            directories.forEach(paths::add);
        }
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        if (expectation.exception == null) {
            CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
            Optional<List<Argument<?>>> match = expression.match(requireNonNull(expectation.text));
            List<?> values = match.isEmpty() ? null : match.stream()
                    .flatMap(Collection::stream)
                    .map(Argument::getValue)
                    .collect(Collectors.toList());

            if (expectation.expectedArgs == null) {
                assertThat(values, nullValue());
            } else {
                assertThat(values, CustomMatchers.equalOrCloseTo(expectation.expectedArgs));
            }
        } else {
            Executable executable = () -> {
                CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
                if (expectation.text != null) {
                    expression.match(expectation.text);
                }
            };
            CucumberExpressionException exception = assertThrows(CucumberExpressionException.class, executable);
            assertThat(exception.getMessage(), equalTo(expectation.exception));
        }
    }
    // Misc tests

    @Test
    void exposes_source() {
        String expr = "I have {int} cuke(s)";
        assertEquals(expr, new CucumberExpression(expr, new ParameterTypeRegistry(Locale.ENGLISH)).getSource());
    }

    // Java-specific
    @Test
    void matches_anonymous_parameter_type_with_hint() {
        assertEquals(singletonList(0.22f), match("{}", "0.22", Float.class));
    }

    @Test
    void documents_match_arguments() {
        String expr = "I have {int} cuke(s)";
        Expression expression = new CucumberExpression(expr, parameterTypeRegistry);
        Optional<List<Argument<?>>> args = expression.match("I have 7 cukes");
        assertNotNull(args);
        assertEquals(7, args.get().get(0).getValue());
    }

    @Test
    void matches_byte() {
        assertEquals(singletonList(Byte.MAX_VALUE), match("{byte}", "127"));
    }

    @Test
    void matches_short() {
        assertEquals(singletonList(Short.MAX_VALUE), match("{short}", String.valueOf(Short.MAX_VALUE)));
    }

    @Test
    void matches_long() {
        assertEquals(singletonList(Long.MAX_VALUE), match("{long}", String.valueOf(Long.MAX_VALUE)));
    }

    @Test
    void matches_biginteger() {
        BigInteger bigInteger = BigInteger.valueOf(Long.MAX_VALUE);
        bigInteger = bigInteger.pow(10);
        assertEquals(singletonList(bigInteger), match("{biginteger}", bigInteger.toString()));
    }

    @Test
    void matches_bigdecimal() {
        BigDecimal bigDecimal = BigDecimal.valueOf(Math.PI);
        assertEquals(singletonList(bigDecimal), match("{bigdecimal}", bigDecimal.toString()));
    }

    @Test
    void matches_double_with_comma_for_locale_using_comma() {
        List<?> values = match("{double}", "1,22", Locale.FRANCE);
        assertEquals(singletonList(1.22), values);
    }

    @Test
    void matches_float_with_zero() {
        List<?> values = match("{float}", "0", Locale.ENGLISH);
        assertEquals(singletonList(0.0f), values);
    }

    @Test
    void unmatched_optional_groups_have_null_values() {
        ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "textAndOrNumber",
                singletonList("([A-Z]+)?(?: )?([0-9]+)?"),
                new TypeReference<List<String>>() {
                }.getType(),
                new CaptureGroupTransformer<List<String>>() {
                    @Override
                    public List<String> transform(@Nullable String[] args) {
                        return Arrays.asList(args);
                    }
                },
                false,
                false)
        );
        assertThat(match("{textAndOrNumber}", "TLA", parameterTypeRegistry), is(singletonList(asList("TLA", null))));
        assertThat(match("{textAndOrNumber}", "123", parameterTypeRegistry), is(singletonList(asList(null, "123"))));
    }

    @Nullable
    private List<?> match(String expr, String text, Type... typeHints) {
        return match(expr, text, parameterTypeRegistry, typeHints);
    }

    @Nullable
    private List<?> match(String expr, String text, Locale locale, Type... typeHints) {
        ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(locale);
        return match(expr, text, parameterTypeRegistry, typeHints);
    }

    @Nullable
    private List<?> match(String expr, String text, ParameterTypeRegistry parameterTypeRegistry, Type... typeHints) {
        CucumberExpression expression = new CucumberExpression(expr, parameterTypeRegistry);
        Optional<List<Argument<?>>> match = expression.match(text, typeHints);
        if (match.isEmpty()) {
            return null;
        } else {
            return match.stream()
                    .flatMap(Collection::stream)
                    .map(Argument::getValue)
                    .map(Object.class::cast)
                    .toList();
        }
    }


    public record Expectation(String expression, @Nullable String text, @Nullable List<?> expectedArgs,
                              @Nullable String exception) {
    }

    @NullMarked
    static class Converter implements ArgumentConverter {
        Yaml yaml = new Yaml();

        @Override
        public Expectation convert(@Nullable Object source, ParameterContext context) throws ArgumentConversionException {
            if (source == null) {
                throw new ArgumentConversionException("Could not load null");
            }

            try {
                Path path = (Path) source;
                InputStream inputStream = newInputStream(path);
                Map<String, ?> document = yaml.loadAs(inputStream, Map.class);
                return new Expectation(
                        (String) requireNonNull(document.get("expression")),
                        (String) document.get("text"),
                        (List<?>) document.get("expected_args"),
                        (String) document.get("exception")
                );
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }
}
