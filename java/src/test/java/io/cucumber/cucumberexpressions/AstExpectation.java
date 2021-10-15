package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.Ast.Node;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;

import static java.nio.file.Files.newInputStream;

class AstExpectation {
    public String expression;
    public YamlableNode expected_ast;
    public String exception;

    static class Converter implements ArgumentConverter {
        Yaml yaml = new Yaml();

        @Override
        public AstExpectation convert(Object source, ParameterContext context) throws ArgumentConversionException {
            try {
                Path path = (Path) source;
                InputStream inputStream = newInputStream(path);
                return yaml.loadAs(inputStream, AstExpectation.class);
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
