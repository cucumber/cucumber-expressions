package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;
import org.junit.jupiter.params.shadow.de.siegmar.fastcsv.util.Nullable;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

public class ParameterTypeRegistryTest {

    private static final String CAPITALISED_WORD = "[A-Z]+\\w+";

    private final ParameterTypeRegistry registry = new ParameterTypeRegistry(Locale.ENGLISH);

    @Test
    public void does_not_allow_more_than_one_preferential_parameter_type_for_each_regexp() {

        registry.defineParameterType(new ParameterType<>("name", CAPITALISED_WORD, Name.class, Name::new, false, true));
        registry.defineParameterType(new ParameterType<>("person", CAPITALISED_WORD, Person.class, Person::new, false, false));

        Executable testMethod = () -> registry.defineParameterType(new ParameterType<>(
                "place",
                CAPITALISED_WORD,
                Place.class,
                Place::new,
                false,
                true
        ));

        var exception = assertThrows(CucumberExpressionException.class, testMethod);
        assertThat(exception).hasMessage("There can only be one preferential parameter type per regexp. The regexp /[A-Z]+\\w+/ is used for two preferential parameter types, {name} and {place}");
    }

    @Test
    public void looks_up_preferential_parameter_type_by_regexp() {
        var name = new ParameterType<>("name", CAPITALISED_WORD, Name.class, Name::new, false, false);
        var person = new ParameterType<>("person", CAPITALISED_WORD, Person.class, Person::new, false, true);
        var place = new ParameterType<>("place", CAPITALISED_WORD, Place.class, Place::new, false, false);
        registry.defineParameterType(name);
        registry.defineParameterType(person);
        registry.defineParameterType(place);
        var parameter = registry.lookupByRegexp(CAPITALISED_WORD, Pattern.compile("([A-Z]+\\w+) and ([A-Z]+\\w+)"), "Lisa and Bob");
        assertThat(parameter).isSameAs(person);
    }

    @Test
    public void throws_ambiguous_exception_on_lookup_when_no_parameter_types_are_preferential() {
        var name = new ParameterType<>("name", CAPITALISED_WORD, Name.class, Name::new, true, false);
        var person = new ParameterType<>("person", CAPITALISED_WORD, Person.class, Person::new, true, false);
        var place = new ParameterType<>("place", CAPITALISED_WORD, Place.class, Place::new, true, false);
        registry.defineParameterType(name);
        registry.defineParameterType(person);
        registry.defineParameterType(place);

        String expected = """
                Your Regular Expression /([A-Z]+\\w+) and ([A-Z]+\\w+)/
                matches multiple parameter types with regexp /[A-Z]+\\w+/:
                   {name}
                   {person}
                   {place}
                
                I couldn't decide which one to use. You have two options:
                
                1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:
                   {name} and {name}
                   {name} and {person}
                   {name} and {place}
                   {person} and {name}
                   {person} and {person}
                   {person} and {place}
                   {place} and {name}
                   {place} and {person}
                   {place} and {place}
                
                2) Make one of the parameter types preferential and continue to use a Regular Expression.
                
                """;

        Executable testMethod = () -> registry.lookupByRegexp(CAPITALISED_WORD, Pattern.compile("([A-Z]+\\w+) and ([A-Z]+\\w+)"), "Lisa and Bob");
        var exception = assertThrows(AmbiguousParameterTypeException.class, testMethod);
        assertThat(exception).hasMessage(expected);
    }

    @Test
    public void does_not_allow_anonymous_parameter_type_to_be_registered() {
        Executable testMethod = () -> registry.defineParameterType(new ParameterType<>("", ".*", Object.class, (Transformer<Object>) arg -> arg));

        var exception = assertThrows(DuplicateTypeNameException.class, testMethod);
        assertThat(exception).hasMessage("The anonymous parameter type has already been defined");
    }

    @Test
    public void parse_decimal_numbers_in_english() {
        ExpressionFactory factory = new ExpressionFactory(new ParameterTypeRegistry(Locale.ENGLISH));
        Expression expression = factory.createExpression("{bigdecimal}");

        assertThat(expression.match("")).isNull();
        assertThat(expression.match(".")).isNull();
        assertThat(expression.match(",")).isNull();
        assertThat(expression.match("-")).isNull();
        assertThat(expression.match("E")).isNull();
        assertThat(expression.match("1,")).isNull();
        assertThat(expression.match(",1")).isNull();
        assertThat(expression.match("1.")).isNull();

        assertThat(expression.match("1")).singleElement().extracting(Argument::getValue).isEqualTo(BigDecimal.ONE);
        assertThat(expression.match("-1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1"));
        assertThat(expression.match("1.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1.1"));
        assertThat(expression.match("1,000")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000"));
        assertThat(expression.match("1,000,0")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("10000"));
        assertThat(expression.match("1,000.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000.1"));
        assertThat(expression.match("1,000,10")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("100010"));
        assertThat(expression.match("1,0.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("10.1"));
        assertThat(expression.match("1,000,000.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000000.1"));
        assertThat(expression.match("-1.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1.1"));

        assertThat(expression.match(".1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("0.1"));
        assertThat(expression.match("-.1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-0.1"));
        assertThat(expression.match("-.10000001")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-0.10000001"));
        // precision 1 with scale -1, can not be expressed as a decimal
        assertThat(expression.match("1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1E1"));
        assertThat(expression.match(".1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1"));
        assertThat(expression.match("E1")).isNull();
        assertThat(expression.match("-.1E-1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-0.01"));
        assertThat(expression.match("-.1E-2")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-0.001"));
        assertThat(expression.match("-.1E+1")).isNull();
        assertThat(expression.match("-.1E+2")).isNull();
        assertThat(expression.match("-.1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1"));
        assertThat(expression.match("-.10E2")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-10"));
    }

    @Test
    public void parse_decimal_numbers_in_german() {
        ExpressionFactory factory = new ExpressionFactory(new ParameterTypeRegistry(Locale.GERMAN));
        Expression expression = factory.createExpression("{bigdecimal}");

        assertThat(expression.match("1.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000.1"));
        assertThat(expression.match("1.000.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000000.1"));
        assertThat(expression.match("-1,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1.1"));
        assertThat(expression.match("-,1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1"));
    }

    @Test
    public void parse_decimal_numbers_in_canadian_french() {
        ExpressionFactory factory = new ExpressionFactory(new ParameterTypeRegistry(Locale.CANADA_FRENCH));
        Expression expression = factory.createExpression("{bigdecimal}");

        assertThat(expression.match("1.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000.1"));
        assertThat(expression.match("1.000.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000000.1"));
        assertThat(expression.match("-1,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1.1"));
        assertThat(expression.match("-,1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1"));
    }

    @Test
    public void parse_decimal_numbers_in_norwegian() {
        ExpressionFactory factory = new ExpressionFactory(new ParameterTypeRegistry(Locale.forLanguageTag("no")));
        Expression expression = factory.createExpression("{bigdecimal}");

        assertThat(expression.match("1.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000.1"));
        assertThat(expression.match("1.000.000,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("1000000.1"));
        assertThat(expression.match("-1,1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1.1"));
        assertThat(expression.match("-,1E1")).singleElement().extracting(Argument::getValue).isEqualTo(new BigDecimal("-1"));
    }

    public static class Name {
        Name(@Nullable String s) {
            assertNotNull(s);
        }
    }

    public static class Person {
        Person(@Nullable String s) {
            assertNotNull(s);
        }
    }

    public static class Place {
        Place(@Nullable String s) {
            assertNotNull(s);
        }
    }

}
