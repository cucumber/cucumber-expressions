package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.Ast.Token;
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
import java.util.Map;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Objects.requireNonNull;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CucumberExpressionTokenizerTest {

    private final CucumberExpressionTokenizer tokenizer = new CucumberExpressionTokenizer();

    static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        try (DirectoryStream<Path> directories = newDirectoryStream(Paths.get("..", "testdata", "cucumber-expression", "tokenizer"))) {
            directories.forEach(paths::add);
        }
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        if (expectation.exception == null) {
            List<Token> tokens = tokenizer.tokenize(expectation.expression);
            assertThat(tokens, is(expectation.expectedTokens));
        } else {
            CucumberExpressionException exception = assertThrows(
                    CucumberExpressionException.class,
                    () -> tokenizer.tokenize(expectation.expression));
            assertThat(exception.getMessage(), is(expectation.exception));
        }
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
                        convertExpectedTokens(expectation),
                        (String) expectation.get("exception")
                );
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }

        @SuppressWarnings("unchecked")
        private @Nullable List<Token> convertExpectedTokens(Map<String, ?> expectation) {
            var expectedAst = (List<Map<String, ?>>) expectation.get("expected_tokens");
            return expectedAst == null ? null : expectedAst.stream().map(this::convertToken).collect(Collectors.toList());
        }

        private Token convertToken(Map<String, ?> expectation) {
            var token = (String) requireNonNull(expectation.get("text"));
            var type = Token.Type.valueOf((String) requireNonNull(expectation.get("type")));
            var start = (int) requireNonNull(expectation.get("start"));
            var end = (int) requireNonNull(expectation.get("end"));
            return new Token(token, type, start, end);
        }

    }

    record Expectation(String expression, @Nullable List<Token> expectedTokens, @Nullable String exception) {
    }
}
