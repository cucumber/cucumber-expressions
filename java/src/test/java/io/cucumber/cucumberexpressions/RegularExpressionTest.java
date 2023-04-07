package io.cucumber.cucumberexpressions;

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
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Arrays.asList;
import static java.util.Collections.emptyList;
import static java.util.Collections.singletonList;
import static java.util.regex.Pattern.compile;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.jupiter.api.Assertions.*;

public class RegularExpressionTest {

    private final ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    private static final String CAPITALISED_WORD = "[A-Z]+\\w+";

    private static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        newDirectoryStream(Paths.get("..", "testdata", "regular-expression", "matching")).forEach(paths::add);
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        RegularExpression expression = new RegularExpression(Pattern.compile(expectation.expression), parameterTypeRegistry);
        List<Argument<?>> match = expression.match(expectation.text);
        List<?> values = match == null ? null : match.stream()
                .map(Argument::getValue)
                .collect(Collectors.toList());

        assertThat(values, CustomMatchers.equalOrCloseTo(expectation.expected_args));
    }

    static class Expectation {
        public String expression;
        public String text;
        public List<?> expected_args;
    }

    static class Converter implements ArgumentConverter {
        Yaml yaml = new Yaml();

        @Override
        public Expectation convert(Object source, ParameterContext context) throws ArgumentConversionException {
            try {
                Path path = (Path) source;
                InputStream inputStream = newInputStream(path);
                return yaml.loadAs(inputStream, Expectation.class);
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }

    @Test
    public void documentation_match_arguments() {
        Pattern expr = Pattern.compile("I have (\\d+) cukes? in my (\\w+) now");
        Expression expression = new RegularExpression(expr, parameterTypeRegistry);
        List<Argument<?>> match = expression.match("I have 7 cukes in my belly now");
        assertEquals(7, match.get(0).getValue());
        assertEquals("belly", match.get(1).getValue());
    }

    @Test
    public void matches_positive_int() {
        List<?> match = match(compile("(\\d+)"), "22");
        assertEquals(singletonList(22), match);
    }

    @Test
    public void matches_positive_int_with_hint() {
        List<?> match = match(compile("(\\d+)"), "22", Integer.class);
        assertEquals(singletonList(22), match);
    }

    @Test
    public void matches_positive_int_with_conflicting_type_hint() {
        List<?> match = match(compile("(\\d+)"), "22", String.class);
        assertEquals(singletonList("22"), match);
    }

    @Test
    public void matches_nested_capture_group_without_match() {
        List<?> match = match(compile("^a user( named \"([^\"]*)\")?$"), "a user");
        assertEquals(singletonList(null), match);
    }

    @Test
    public void matches_nested_capture_group_with_match() {
        List<?> match = match(compile("^a user( named \"([^\"]*)\")?$"), "a user named \"Charlie\"");
        assertEquals(singletonList("Charlie"), match);
    }

    @Test
    public void ignores_non_capturing_groups() {
        String expr = "(\\S+) ?(can|cannot)? (?:delete|cancel) the (\\d+)(?:st|nd|rd|th) (attachment|slide) ?(?:upload)?";
        String step = "I can cancel the 1st slide upload";
        List<?> match = match(compile(expr), step);
        assertEquals(asList("I", "can", 1, "slide"), match);
    }

    @Test
    public void matches_capture_group_nested_in_optional_one() {
        String regex = "^a (pre-commercial transaction |pre buyer fee model )?purchase(?: for \\$(\\d+))?$";
        assertEquals(asList(null, null), match(compile(regex), "a purchase"));
        assertEquals(asList(null, 33), match(compile(regex), "a purchase for $33"));
        assertEquals(asList("pre buyer fee model ", null), match(compile(regex), "a pre buyer fee model purchase"));
    }

    @Test
    public void works_with_escaped_parenthesis() {
        String expr = "Across the line\\(s\\)";
        String step = "Across the line(s)";
        List<?> match = match(compile(expr), step);
        assertEquals(emptyList(), match);
    }

    @Test
    public void exposes_source_and_regexp() {
        String regexp = "I have (\\d+) cukes? in my (.+) now";
        RegularExpression expression = new RegularExpression(Pattern.compile(regexp),
                new ParameterTypeRegistry(Locale.ENGLISH));
        assertEquals(regexp, expression.getSource());
        assertEquals(regexp, expression.getRegexp().pattern());
    }

    @Test
    public void uses_float_type_hint_when_group_doesnt_match_known_param_type() {
        List<?> match = match(compile("a (.*)"), "a 22", Float.class);
        assertEquals(Float.class, match.get(0).getClass());
        assertEquals(22f, (Float) match.get(0), 0.00001);
    }

    @Test
    public void uses_double_type_hint_when_group_doesnt_match_known_param_type() {
        List<?> match = match(compile("a (\\d\\d.\\d)"), "a 33.5", Double.class);
        assertEquals(Double.class, match.get(0).getClass());
        assertEquals(33.5d, (Double) match.get(0), 0.00001);
    }

    @Test
    public void matches_empty_string() {
        List<?> match = match(compile("^The value equals \"([^\"]*)\"$"), "The value equals \"\"", String.class);
        assertEquals(String.class, match.get(0).getClass());
        assertEquals("", match.get(0));
    }

    @Test
    public void uses_two_type_hints_to_resolve_anonymous_parameter_type() {
        List<?> match = match(compile("a (.*) and a (.*)"), "a 22 and a 33.5", Float.class, Double.class);

        assertEquals(Float.class, match.get(0).getClass());
        assertEquals(22f, (Float) match.get(0), 0.00001);

        assertEquals(Double.class, match.get(1).getClass());
        assertEquals(33.5d, (Double) match.get(1), 0.00001);
    }

    @Test
    public void retains_all_content_captured_by_the_capture_group() {
        List<?> match = match(compile("a quote ([\"a-z ]+)"), "a quote \" and quote \"", String.class);
        assertEquals(singletonList("\" and quote \""), match);
    }

    @Test
    public void uses_parameter_type_registry_when_parameter_type_is_defined() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "[\"a-z ]+",
                String.class,
                new Transformer<String>() {
                    @Override
                    public String transform(String s) {
                        return s.toUpperCase();
                    }
                }
        ));
        List<?> match = match(compile("a quote ([\"a-z ]+)"), "a quote \" and quote \"", String.class);
        assertEquals(singletonList("\" AND QUOTE \""), match);
    }

    @Test
    public void ignores_type_hint_when_parameter_type_has_strong_type_hint() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "one|two|three",
                Integer.class,
                new Transformer<Integer>() {
                    @Override
                    public Integer transform(String s) {
                        return 42;
                    }
                }, false, false, true
        ));
        assertEquals(asList(42), match(compile("(one|two|three)"), "one", String.class));
    }

    @Test
    public void follows_type_hint_when_parameter_type_does_not_have_strong_type_hint() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                "one|two|three",
                Integer.class,
                new Transformer<Integer>() {
                    @Override
                    public Integer transform(String s) {
                        return 42;
                    }
                }, false, false, false
        ));
        assertEquals(asList("one"), match(compile("(one|two|three)"), "one", String.class));
    }

    @Test
    public void matches_anonymous_parameter_type_with_hint() {
        assertEquals(singletonList(0.22f), match(compile("(.*)"), "0.22", Float.class));
    }

    @Test
    public void matches_anonymous_parameter_type() {
        assertEquals(singletonList("0.22"), match(compile("(.*)"), "0.22"));
    }

    @Test
    public void matches_optional_boolean_capture_group() {
        Pattern pattern = compile("^(true|false)?$");
        assertEquals(singletonList(true), match(pattern, "true", Boolean.class));
        assertEquals(singletonList(false), match(pattern, "false", Boolean.class));
        assertEquals(singletonList(null), match(pattern, "", Boolean.class));
    }

    @Test
    public void parameter_types_can_be_optional_when_used_in_regex() {
        parameterTypeRegistry.defineParameterType(new ParameterType<>(
                "test",
                ".+",
                String.class,
                new Transformer<String>() {
                    @Override
                    public String transform(String s) {
                        return s;
                    }
                }
        ));
        List<?> match = match(compile("^text(?: (.+))? text2$"), "text text2", String.class);
        assertEquals(singletonList(null), match);
    }

    @Test
    public void looks_up_preferential_parameter_type_by_regexp() {
        ParameterType<ParameterTypeRegistryTest.Name> name = new ParameterType<>("name", CAPITALISED_WORD, ParameterTypeRegistryTest.Name.class, ParameterTypeRegistryTest.Name::new, false, false);
        ParameterType<ParameterTypeRegistryTest.Person> person = new ParameterType<>("person", CAPITALISED_WORD, ParameterTypeRegistryTest.Person.class, ParameterTypeRegistryTest.Person::new, false, true);
        ParameterType<ParameterTypeRegistryTest.Place> place = new ParameterType<>("place", CAPITALISED_WORD, ParameterTypeRegistryTest.Place.class, ParameterTypeRegistryTest.Place::new, false, false);
        parameterTypeRegistry.defineParameterType(name);
        parameterTypeRegistry.defineParameterType(person);
        parameterTypeRegistry.defineParameterType(place);
        assertSame(person, RegularExpression.lookupByRegexp(CAPITALISED_WORD, Pattern.compile("([A-Z]+\\w+) and ([A-Z]+\\w+)"), "Lisa and Bob", parameterTypeRegistry));
    }

    @Test
    public void throws_ambiguous_exception_on_lookup_when_no_parameter_types_are_preferential() {
        ParameterType<ParameterTypeRegistryTest.Name> name = new ParameterType<>("name", CAPITALISED_WORD, ParameterTypeRegistryTest.Name.class, ParameterTypeRegistryTest.Name::new, true, false);
        ParameterType<ParameterTypeRegistryTest.Person> person = new ParameterType<>("person", CAPITALISED_WORD, ParameterTypeRegistryTest.Person.class, ParameterTypeRegistryTest.Person::new, true, false);
        ParameterType<ParameterTypeRegistryTest.Place> place = new ParameterType<>("place", CAPITALISED_WORD, ParameterTypeRegistryTest.Place.class, ParameterTypeRegistryTest.Place::new, true, false);
        parameterTypeRegistry.defineParameterType(name);
        parameterTypeRegistry.defineParameterType(person);
        parameterTypeRegistry.defineParameterType(place);

        String expected = "" +
                "Your Regular Expression /([A-Z]+\\w+) and ([A-Z]+\\w+)/\n" +
                "matches multiple parameter types with regexp /[A-Z]+\\w+/:\n" +
                "   {name}\n" +
                "   {person}\n" +
                "   {place}\n" +
                "\n" +
                "I couldn't decide which one to use. You have two options:\n" +
                "\n" +
                "1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:\n" +
                "   {name} and {name}\n" +
                "   {name} and {person}\n" +
                "   {name} and {place}\n" +
                "   {person} and {name}\n" +
                "   {person} and {person}\n" +
                "   {person} and {place}\n" +
                "   {place} and {name}\n" +
                "   {place} and {person}\n" +
                "   {place} and {place}\n" +
                "\n" +
                "2) Make one of the parameter types preferential and continue to use a Regular Expression.\n" +
                "\n";

        final Executable testMethod = () -> RegularExpression.lookupByRegexp(CAPITALISED_WORD, Pattern.compile("([A-Z]+\\w+) and ([A-Z]+\\w+)"), "Lisa and Bob", parameterTypeRegistry);

        final AmbiguousParameterTypeException thrownException = assertThrows(AmbiguousParameterTypeException.class, testMethod);
        assertThat("Unexpected message", thrownException.getMessage(), is(equalTo(expected)));
    }

    private List<?> match(Pattern pattern, String text, Type... types) {
        RegularExpression regularExpression = new RegularExpression(pattern, parameterTypeRegistry);
        List<Argument<?>> arguments = regularExpression.match(text, types);
        List<Object> values = new ArrayList<>();
        for (Argument<?> argument : arguments) {
            values.add(argument.getValue());
        }
        return values;
    }

}
