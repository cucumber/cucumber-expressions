package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.Ast.Node;
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
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import static java.nio.file.Files.newDirectoryStream;
import static java.nio.file.Files.newInputStream;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CucumberExpressionParserTest {

    private final CucumberExpressionParser parser = new CucumberExpressionParser();

    private static List<Path> acceptance_tests_pass() throws IOException {
        List<Path> paths = new ArrayList<>();
        newDirectoryStream(Paths.get("..", "testdata", "cucumber-expression", "parser")).forEach(paths::add);
        paths.sort(Comparator.naturalOrder());
        return paths;
    }

    @ParameterizedTest
    @MethodSource
    void acceptance_tests_pass(@ConvertWith(Converter.class) Expectation expectation) {
        if (expectation.exception == null) {
            Node node = parser.parse(expectation.expression);
            assertThat(node, is(expectation.expected_ast.toNode()));
        } else {
            CucumberExpressionException exception = assertThrows(
                    CucumberExpressionException.class,
                    () -> parser.parse(expectation.expression));
            assertThat(exception.getMessage(), is(expectation.exception));
        }
    }

    static class Expectation {
        public String expression;
        public YamlableNode expected_ast;
        public String exception;
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

    static class YamlableNode {
        public Ast.Node.Type type;
        public List<YamlableNode> nodes;
        public String token;
        public int start;
        public int end;

        public Node toNode() {
            if (token != null) {
                return new Node(type, start, end, token);
            } else {
                return new Node(type, start, end, nodes.stream().map(YamlableNode::toNode).collect(Collectors.toList()));
            }
        }
    }
}
