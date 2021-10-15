package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.params.converter.ArgumentConversionException;
import org.junit.jupiter.params.converter.ArgumentConverter;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.List;

import static java.nio.file.Files.newInputStream;

class RegularExpressionExpectation {
    public String expression;
    public String text;
    public List<?> expected_args;

    static class Converter implements ArgumentConverter {
        Yaml yaml = new Yaml();

        @Override
        public RegularExpressionExpectation convert(Object source, ParameterContext context) throws ArgumentConversionException {
            try {
                Path path = (Path) source;
                InputStream inputStream = newInputStream(path);
                return yaml.loadAs(inputStream, RegularExpressionExpectation.class);
            } catch (IOException e) {
                throw new ArgumentConversionException("Could not load " + source, e);
            }
        }
    }
}
