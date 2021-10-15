package io.cucumber.cucumberexpressions;

import org.hamcrest.Matcher;
import org.hamcrest.collection.IsIterableContainingInOrder;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.converter.ConvertWith;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.IOException;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.util.Arrays.asList;
import static java.util.Collections.singletonList;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.closeTo;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.core.Is.is;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CucumberExpressionTest {
    private final ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    private static List<Path> expression_acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        newDirectoryStream(Paths.get("..", "testdata", "expression")).forEach(paths::add);
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    private static List<Path> regex_acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        newDirectoryStream(Paths.get("..", "testdata", "regex")).forEach(paths::add);
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void expression_acceptance_tests_pass(@ConvertWith(ExpressionExpectation.Converter.class) ExpressionExpectation expectation) {
        if (expectation.exception == null) {
            CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
            List<Argument<?>> match = expression.match(expectation.text);
            List<?> values = match == null ? null : match.stream()
                    .map(Argument::getValue)
                    .map(e -> e instanceof Float ? ((Float)e).doubleValue() : e)
                    .collect(Collectors.toList());

            assertThat(values, equalOrCloseTo(expectation.expected_args));
        } else {
            Executable executable = () -> {
                CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
                expression.match(expectation.text);
            };
            CucumberExpressionException exception = assertThrows(CucumberExpressionException.class, executable);
            assertThat(exception.getMessage(), equalTo(expectation.exception));
        }
    }

    public static Matcher<Iterable<?>> equalOrCloseTo(List<?> list) {
        if (list == null || list.isEmpty()) return equalTo(list);
        List<Matcher<?>> matchers = list.stream().map(e -> e instanceof Double ? closeTo(((Double) e), 0.0001) : equalTo(e)).collect(Collectors.toList());
        return new IsIterableContainingInOrder(matchers);
    }

    @ParameterizedTest
    @MethodSource
    void regex_acceptance_tests_pass(@ConvertWith(RegexExpectation.Converter.class) RegexExpectation expectation) {
        CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
        assertEquals(expectation.expected_regex, expression.getRegexp().pattern());
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
        List<Argument<?>> args = expression.match("I have 7 cukes");
        assertEquals(7, args.get(0).getValue());
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
        assertEquals(0.0f, values.get(0));
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
                    public List<String> transform(String... args) {
                        return asList(args);
                    }
                },
                false,
                false)
        );
        assertThat(match("{textAndOrNumber}", "TLA", parameterTypeRegistry), is(singletonList(asList("TLA", null))));
        assertThat(match("{textAndOrNumber}", "123", parameterTypeRegistry), is(singletonList(asList(null, "123"))));
    }

    private List<?> match(String expr, String text, Type... typeHints) {
        return match(expr, text, parameterTypeRegistry, typeHints);
    }

    private List<?> match(String expr, String text, Locale locale, Type... typeHints) {
        ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(locale);
        return match(expr, text, parameterTypeRegistry, typeHints);
    }

    private List<?> match(String expr, String text, ParameterTypeRegistry parameterTypeRegistry, Type... typeHints) {
        CucumberExpression expression = new CucumberExpression(expr, parameterTypeRegistry);
        List<Argument<?>> args = expression.match(text, typeHints);
        if (args == null) {
            return null;
        } else {
            List<Object> list = new ArrayList<>();
            for (Argument<?> arg : args) {
                Object value = arg.getValue();
                list.add(value);
            }
            return list;
        }
    }
}
