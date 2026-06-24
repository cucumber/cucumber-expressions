package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;

import java.text.DecimalFormatSymbols;
import java.util.AbstractMap.SimpleEntry;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.function.Function;
import java.util.stream.Stream;

import static java.util.Comparator.comparing;
import static java.util.stream.Collectors.groupingBy;

class KeyboardFriendlyDecimalFormatSymbolsTest {

    @Test
    void listMinusSigns(){
        System.out.println("Original minus signs:");
        listMinusSigns(DecimalFormatSymbols::getInstance);
        System.out.println();
        System.out.println("Friendly minus signs:");
        listMinusSigns(KeyboardFriendlyDecimalFormatSymbols::getInstance);
        System.out.println();
    }

    private static void listMinusSigns(Function<Locale, DecimalFormatSymbols> supplier) {
        getAvailableLocalesAsStream()
                .collect(groupingBy(locale -> supplier.apply(locale).getMinusSign()))
                .forEach((c, locales) -> System.out.println(render(c) + " " + render(locales)));
    }

    @Test
    void listDecimalAndGroupingSeparators(){
        System.out.println("Original decimal and group separators:");
        listDecimalAndGroupingSeparators(DecimalFormatSymbols::getInstance);
        System.out.println();
        System.out.println("Friendly decimal and group separators:");
        listDecimalAndGroupingSeparators(KeyboardFriendlyDecimalFormatSymbols::getInstance);
        System.out.println();
    }

    private static void listDecimalAndGroupingSeparators(Function<Locale, DecimalFormatSymbols> supplier) {
        getAvailableLocalesAsStream()
                .collect(groupingBy(locale -> {
                    DecimalFormatSymbols symbols = supplier.apply(locale);
                    return new SimpleEntry<>(symbols.getDecimalSeparator(), symbols.getGroupingSeparator());
                }))
                .entrySet()
                .stream()
                .sorted(comparing(entry -> entry.getKey().getKey()))
                .forEach(entry -> {
                    SimpleEntry<Character, Character> characters = entry.getKey();
                    List<Locale> locales = entry.getValue();
                    System.out.println(render(characters.getKey()) + " " + render(characters.getValue()) + " " + render(locales));
                });
    }

    @Test
    void listExponentSigns(){
        System.out.println("Original exponent signs:");
        listExponentSigns(DecimalFormatSymbols::getInstance);
        System.out.println();
        System.out.println("Friendly exponent signs:");
        listExponentSigns(KeyboardFriendlyDecimalFormatSymbols::getInstance);
        System.out.println();
    }

    private static void listExponentSigns(Function<Locale, DecimalFormatSymbols> supplier) {
        getAvailableLocalesAsStream()
                .collect(groupingBy(locale -> supplier.apply(locale).getExponentSeparator()))
                .forEach((s, locales) -> {
                    if (s.length() == 1) {
                        System.out.println(render(s.charAt(0)) + " " + render(locales));
                    } else {
                        System.out.println(s + " " + render(locales));
                    }
                });
    }

    private static Stream<Locale> getAvailableLocalesAsStream() {
        return Arrays.stream(DecimalFormatSymbols.getAvailableLocales());
    }

    private static String render(Character character) {
        return character + " (" + (int) character + ")";
    }

    private static String render(List<Locale> locales) {
        return locales.size() + ": " + locales.stream()
                .sorted(comparing(Locale::getDisplayName))
                .map(Locale::getDisplayName)
                .toList();
    }

}
