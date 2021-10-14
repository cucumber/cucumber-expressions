package io.cucumber.cucumberexpressions;

import io.cucumber.cucumberexpressions.Ast.Token;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.List;

import static java.nio.file.Files.newInputStream;

class TokenExpectation {
    public String expression;
    public List<YamlableToken> expected_tokens;
    public String exception;

    static class Converter implements ArgumentConverter {
        Yaml yaml = new Yaml();

        @Override
        public TokenExpectation convert(Object source, ParameterContext context) throws ArgumentConversionException {
            try {
                Path path = (Path) source;
                InputStream inputStream = newInputStream(path);
                return yaml.loadAs(inputStream, TokenExpectation.class);
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }

    static class YamlableToken {
        public String text;
        public Token.Type type;
        public int start;
        public int end;

        public Token toToken() {
            return new Token(text, type, start, end);
        }
    }
}
