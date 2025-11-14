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
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static java.util.Objects.requireNonNull;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CucumberExpressionParserTest {

    private final CucumberExpressionParser parser = new CucumberExpressionParser();

    static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        try (var directories = newDirectoryStream(Paths.get("..", "testdata", "cucumber-expression", "parser"))) {
            directories.forEach(paths::add);
        }
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        if (expectation.exception == null) {
            Node node = parser.parse(expectation.expression);
            assertThat(node, equalTo(expectation.expectedAst));
        } else {
            CucumberExpressionException exception = assertThrows(
                    CucumberExpressionException.class,
                    () -> parser.parse(expectation.expression));
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
                        convertExpectedAst(expectation),
                        (String) expectation.get("exception")
                );
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }

        @SuppressWarnings("unchecked")
        private @Nullable Node convertExpectedAst(Map<String, ?> expectation) {
            var expectedAst = (Map<String, ?>) expectation.get("expected_ast");
            return expectedAst == null ? null : convertNode(expectedAst);
        }

        private Node convertNode(Map<String, ?> expectation){
            var type = Node.Type.valueOf((String) requireNonNull(expectation.get("type")));
            var nodes = getNodes(expectation).stream().map(this::convertNode).collect(Collectors.toList());
            var token = (String) expectation.get("token");
            var start = (int) requireNonNull(expectation.get("start"));
            var end = (int) requireNonNull(expectation.get("end"));
            if (token != null) {
                return new Node(type, start, end, token);
            } else {
                return new Node(type, start, end, nodes);
            }
        }

        @SuppressWarnings("unchecked")
        private List<Map<String, ?>> getNodes(Map<String, ?> expectation) {
            var nodes = expectation.get("nodes");
            return nodes != null ? (List<Map<String, ?>>) nodes : Collections.emptyList();
        }
    }

    record Expectation(String expression, @Nullable Node expectedAst, @Nullable String exception) {

    }

}
