package io.cucumber.cucumberexpressions;

import org.jspecify.annotations.NullMarked;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;

import java.util.Arrays;
import java.util.Collections;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

class PatternCompilerProviderTest {

    @BeforeEach
    void setUp() {
        PatternCompilerProvider.service = null;
    }

    @Test
    void use_default_compiler_if_none_registered() {
        PatternCompilerProvider.getCompiler();
        assertThat(PatternCompilerProvider.service)
                .extracting(Object::getClass)
                .isEqualTo(DefaultPatternCompiler.class);
    }

    @Test
    void use_found_pattern_compiler_if_one_provided() {
        PatternCompiler compiler = new TestPatternCompiler();
        PatternCompiler found = PatternCompilerProvider.findPatternCompiler(Collections.singletonList(compiler).iterator());
        assertThat(found).isSameAs(compiler);
    }

    @Test
    void throws_error_if_more_than_one_pattern_compiler() {
        Executable testMethod = () -> PatternCompilerProvider.findPatternCompiler(Arrays.asList(new DefaultPatternCompiler(), new TestPatternCompiler()).iterator());
        var exception = assertThrows(IllegalStateException.class, testMethod);
        assertThat(exception).hasMessage("More than one PatternCompiler: [class io.cucumber.cucumberexpressions.DefaultPatternCompiler, class io.cucumber.cucumberexpressions.PatternCompilerProviderTest$TestPatternCompiler]");
    }

    @NullMarked
    private static final class TestPatternCompiler implements PatternCompiler {

        @Override
        public Pattern compile(String regexp, int flags) {
            return Pattern.compile(regexp, flags);
        }
    }

}
