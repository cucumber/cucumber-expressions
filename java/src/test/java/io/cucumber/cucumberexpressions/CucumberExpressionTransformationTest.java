package io.cucumber.cucumberexpressions;

import org.jspecify.annotations.NullMarked;
import org.jspecify.annotations.Nullable;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.junit.jupiter.params.converter.ConvertWith;
import org.junit.jupiter.params.provider.MethodSource;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Objects.requireNonNull;
import static org.junit.jupiter.api.Assertions.assertEquals;

class CucumberExpressionTransformationTest {
    private final ParameterTypeRegistry parameterTypeRegistry = new ParameterTypeRegistry(Locale.ENGLISH);

    static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        try(DirectoryStream<Path> directories = newDirectoryStream(Paths.get("..", "testdata", "cucumber-expression", "transformation"))) {
            directories.forEach(paths::add);
        }
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        CucumberExpression expression = new CucumberExpression(expectation.expression, parameterTypeRegistry);
        assertEquals(expectation.expectedRegex, expression.getRegexp().pattern());
    }

    record Expectation(String expression, String expectedRegex) {
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
                        (String) requireNonNull(expectation.get("expected_regex")));
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }
}
