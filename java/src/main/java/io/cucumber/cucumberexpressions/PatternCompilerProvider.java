package io.cucumber.cucumberexpressions;

import org.jspecify.annotations.Nullable;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.ServiceLoader;

final class PatternCompilerProvider {
    // visible from tests
    static @Nullable PatternCompiler service;

    private PatternCompilerProvider() {
    }

    static synchronized PatternCompiler getCompiler() {
        if (service == null) {
            ServiceLoader<PatternCompiler> loader = ServiceLoader.load(PatternCompiler.class);
            Iterator<PatternCompiler> iterator = loader.iterator();
            service = findPatternCompiler(iterator);
        }
        return service;
    }

    static PatternCompiler findPatternCompiler(Iterator<PatternCompiler> iterator) {
        if (iterator.hasNext()) {
            PatternCompiler service = iterator.next();
            if (iterator.hasNext()) {
                throwMoreThanOneCompilerException(service, iterator);
            }
            return service;
        }
        return new DefaultPatternCompiler();
    }

    private static void throwMoreThanOneCompilerException(PatternCompiler service, Iterator<PatternCompiler> iterator) {
        List<Class<? extends PatternCompiler>> allCompilers = new ArrayList<>();
        allCompilers.add(service.getClass());
        while (iterator.hasNext()) {
            allCompilers.add(iterator.next().getClass());
        }
        throw new IllegalStateException("More than one PatternCompiler: " + allCompilers);
    }
}
