package io.cucumber.cucumberexpressions;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.shadow.de.siegmar.fastcsv.util.Nullable;

import java.util.ArrayList;
import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;

import static java.util.Arrays.asList;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class ParameterTypeComparatorTest {

    @Test
    public void sorts_parameter_types_by_preferential_then_name() {
        SortedSet<ParameterType<?>> set = new TreeSet<>();
        set.add(new ParameterType<>("c", "c", C.class, C::new, false, true));
        set.add(new ParameterType<>("a", "a", A.class, A::new, false, false));
        set.add(new ParameterType<>("d", "d", D.class, D::new, false, false));
        set.add(new ParameterType<>("b", "b", B.class, B::new, false, true));

        List<String> names = new ArrayList<>();
        for (ParameterType<?> parameterType : set) {
            names.add(parameterType.getName());
        }
        assertEquals(asList("b", "c", "a", "d"), names);
    }

    public static class A {
        A(@Nullable String s) {
            assertNotNull(s);
        }
    }

    public static class B {
        B(@Nullable String s) {
            assertNotNull(s);
        }
    }

    public static class C {
        C(@Nullable String s) {
            assertNotNull(s);
        }
    }

    public static class D {
        D(@Nullable String s) {
            assertNotNull(s);
        }
    }
}
