package io.cucumber.cucumberexpressions;

import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.hamcrest.collection.IsIterableContainingInOrder;
import org.hamcrest.core.IsEqual;
import org.hamcrest.number.IsCloseTo;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.List;
import java.util.stream.Collectors;

import static org.hamcrest.Matchers.closeTo;
import static org.hamcrest.Matchers.equalTo;

public class CustomMatchers {
    public static Matcher<Iterable<?>> equalOrCloseTo(List<?> list) {
        if (list == null || list.isEmpty()) return equalTo(list);
        List<Matcher<?>> matchers = list.stream().map(EqualOrCloseTo::new).collect(Collectors.toList());
        return new IsIterableContainingInOrder(matchers);
    }

    private static class EqualOrCloseTo<T> extends BaseMatcher<T> {
        private final Object expectedValue;

        public EqualOrCloseTo(Object expectedValue) {
            this.expectedValue = expectedValue;
        }

        @Override
        public boolean matches(Object actual) {
            if(actual instanceof BigDecimal) {
                return new IsEqual(this.expectedValue).matches(actual.toString());
            } else if(actual instanceof BigInteger) {
                return new IsEqual(this.expectedValue).matches(actual.toString());
            } else if(actual instanceof Double || actual instanceof Float) {
                return new IsCloseTo(((Double)this.expectedValue), 0.0001).matches(((Number)actual).doubleValue());
            } else if(actual instanceof Byte) {
                return new IsEqual(((Integer)this.expectedValue).byteValue()).matches(actual);
            } else if(actual instanceof Number || actual instanceof String || actual == null) {
                return new IsEqual(this.expectedValue).matches(actual);
            }
            throw new RuntimeException("Unsupported type: " + actual.getClass());
        }

        @Override
        public void describeTo(Description description) {
            description.appendValue(expectedValue);
        }
    }
}
