package io.cucumber.cucumberexpressions;

import org.assertj.core.api.InstanceOfAssertFactories;
import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.junit.jupiter.params.converter.ConvertWith;
import org.junit.jupiter.params.provider.MethodSource;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Arrays.asList;
import static java.util.Objects.requireNonNull;
import static java.util.regex.Pattern.compile;
import static org.assertj.core.api.Assertions.assertThat;

final class RegularExpressionTest {

    private final ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        try (var directories = newDirectoryStream(Paths.get("..", "testdata", "regular-expression", "matching"))) {
            directories.forEach(paths::add);
        }
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        RegularExpression expression = new RegularExpression(Pattern.compile(expectation.expression), parameterTypeRegistry);
        Optional<List<Argument<?>>> match = expression.match(expectation.text);
        List<?> values = match.isEmpty() ? null : match.stream()
                .flatMap(Collection::stream)
                .map(Argument::getValue)
                .collect(Collectors.toList());

        assertThat(values).isEqualTo(expectation.expectedArgs);
    }

    @Test
    void documentation_match_arguments() {
        Pattern expr = Pattern.compile("I have (\\d+) cukes? in my (\\w+) now");
        Expression expression = new RegularExpression(expr, parameterTypeRegistry);
        Optional<List<Argument<?>>> match = expression.match("I have 7 cukes in my belly now");
        assertThat(match).get()
                .asInstanceOf(InstanceOfAssertFactories.LIST)
                .map(Argument.class::cast)
                .map(Argument::getValue)                
                .containsExactly(7, "belly");
    }

    @Test
    void matches_positive_int() {
        List<Object> match = match(compile("(\\d+)"), "22");
        assertThat(match).containsExactly(22);
    }

    @Test
    void matches_positive_int_with_hint() {
        List<Object> match = match(compile("(\\d+)"), "22", Integer.class);
        assertThat(match).containsExactly(22);
    }

    @Test
    void matches_positive_int_with_conflicting_type_hint() {
        List<Object> match = match(compile("(\\d+)"), "22", String.class);
        assertThat(match).containsExactly("22");
    }

    @Test
    void matches_nested_capture_group_without_match() {
        List<Object> match = match(compile("^a user( named \"([^\"]*)\")?$"), "a user");
        assertThat(match).containsExactly((Object) null);
    }

    @Test
    void matches_nested_capture_group_with_match() {
        List<Object> match = match(compile("^a user( named \"([^\"]*)\")?$"), "a user named \"Charlie\"");
        assertThat(match).containsExactly("Charlie");
    }

    @Test
    void ignores_non_capturing_groups() {
        String expr = "(\\S+) ?(can|cannot)? (?:delete|cancel) the (\\d+)(?:st|nd|rd|th) (attachment|slide) ?(?:upload)?";
        String step = "I can cancel the 1st slide upload";
        List<Object> match = match(compile(expr), step);
        assertThat(match).isEqualTo(asList("I", "can", 1, "slide"));
    }

    @Test
    void matches_capture_group_nested_in_optional_one() {
        String regex = "^a (pre-commercial transaction |pre buyer fee model )?purchase(?: for \\$(\\d+))?$";
        assertThat(match(Pattern.compile(regex), "a purchase")).containsExactly(null, null);
        assertThat(match(Pattern.compile(regex), "a purchase for $33")).containsExactly(null, 33);
        assertThat(match(Pattern.compile(regex), "a pre buyer fee model purchase")).containsExactly("pre buyer fee model ", null);
    }

    @Test
    void works_with_escaped_parenthesis() {
        String expr = "Across the line\\(s\\)";
        String step = "Across the line(s)";
        List<Object> match = match(compile(expr), step);
        assertThat(match).isEmpty();
    }

    @Test
    void exposes_source_and_regexp() {
        String regexp = "I have (\\d+) cukes? in my (.+) now";
        RegularExpression expression = new RegularExpression(Pattern.compile(regexp), new ParameterTypeRegistry(Locale.ENGLISH));
        assertThat(expression.getSource()).isEqualTo(regexp);
        assertThat(expression.getRegexp().pattern()).isEqualTo(regexp);
    }

    @Test
    void uses_float_type_hint_when_group_doesnt_match_known_param_type() {
        List<Object> match = match(compile("a (.*)"), "a 22", Float.class);
        assertThat(match.get(0).getClass()).isEqualTo(Float.class);
        assertThat(match.get(0)).isEqualTo(22f);
    }

    @Test
    void uses_double_type_hint_when_group_doesnt_match_known_param_type() {
        List<Object> match = match(compile("a (\\d\\d.\\d)"), "a 33.5", Double.class);
        assertThat(match.get(0).getClass()).isEqualTo(Double.class);
        assertThat(match.get(0)).isEqualTo(33.5d);
    }

    @Test
    void matches_empty_string() {
        List<Object> match = match(compile("^The value equals \"([^\"]*)\"$"), "The value equals \"\"", String.class);
        assertThat(match.get(0).getClass()).isEqualTo(String.class);
        assertThat(match.get(0)).isEqualTo("");
    }

    @Test
    void uses_two_type_hints_to_resolve_anonymous_parameter_type() {
        List<Object> match = match(compile("a (.*) and a (.*)"), "a 22 and a 33.5", Float.class, Double.class);

        assertThat(match.get(0).getClass()).isEqualTo(Float.class);
        assertThat(match.get(0)).isEqualTo(22f);

        assertThat(match.get(1).getClass()).isEqualTo(Double.class);
        assertThat(match.get(1)).isEqualTo(33.5d);
    }

    @Test
    void retains_all_content_captured_by_the_capture_group() {
        List<Object> match = match(compile("a quote ([\"a-z ]+)"), "a quote \" and quote \"", String.class);
        assertThat(match).containsExactly("\" and quote \"");
    }

    @Test
    void uses_parameter_type_registry_when_parameter_type_is_defined() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "[\"a-z ]+",
                String.class,
                (@Nullable String s) -> requireNonNull(s).toUpperCase(Locale.US)
        ));
        List<Object> match = match(compile("a quote ([\"a-z ]+)"), "a quote \" and quote \"", String.class);
        assertThat(match).containsExactly("\" AND QUOTE \"");
    }

    @Test
    void ignores_type_hint_when_parameter_type_has_strong_type_hint() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "one|two|three",
                Integer.class,
                s -> 42,
                false,
                false,
                true
        ));
        assertThat(match(Pattern.compile("(one|two|three)"), "one", String.class)).containsExactly(42);
    }

    @Test
    void follows_type_hint_when_parameter_type_does_not_have_strong_type_hint() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "one|two|three",
                Integer.class,
                s -> 42,
                false,
                false,
                false
        ));
        assertThat(match(Pattern.compile("(one|two|three)"), "one", String.class)).containsExactly("one");
    }

    @Test
    void matches_anonymous_parameter_type_with_hint() {
        assertThat(match(Pattern.compile("(.*)"), "0.22", Float.class)).containsExactly(0.22f);
    }

    @Test
    void matches_anonymous_parameter_type() {
        assertThat(match(Pattern.compile("(.*)"), "0.22")).containsExactly("0.22");
    }

    @Test
    void matches_optional_boolean_capture_group() {
        Pattern pattern = compile("^(true|false)?$");
        assertThat(match(pattern, "true", Boolean.class)).containsExactly(true);
        assertThat(match(pattern, "false", Boolean.class)).containsExactly(false);
        assertThat(match(pattern, "", Boolean.class)).containsExactly((Object) null);
    }

    @Test
    void parameter_types_can_be_optional_when_used_in_regex() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                ".+",
                String.class,
                (@Nullable String s) -> s
        ));
        List<Object> match = match(compile("^text(?: (.+))? text2$"), "text text2", String.class);
        assertThat(match).containsExactly((Object) null);
    }

    private List<Object> match(Pattern pattern, String text, Type... types) {
        RegularExpression regularExpression = new RegularExpression(pattern, parameterTypeRegistry);
        Optional<List<Argument<?>>> match = regularExpression.match(text, types);
        return match.stream()
                .flatMap(Collection::stream)
                .map(Argument::getValue)
                .map(Object.class::cast)
                .toList();
    }

    record Expectation(String expression, String text, List<?> expectedArgs) {
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
                Map<String, ?> expectation = yaml.loadAs(inputStream, Map.class);
                return new Expectation(
                        (String) requireNonNull(expectation.get("expression")),
                        (String) requireNonNull(expectation.get("text")),
                        (List<?>) requireNonNull(expectation.get("expected_args")));
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }

}
