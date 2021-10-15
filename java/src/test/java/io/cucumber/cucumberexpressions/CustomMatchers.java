package io.cucumber.cucumberexpressions;

import org.hamcrest.Matcher;
import org.hamcrest.collection.IsIterableContainingInOrder;

import java.util.List;
import java.util.stream.Collectors;

import static org.hamcrest.Matchers.closeTo;
import static org.hamcrest.Matchers.equalTo;

public class CustomMatchers {
    public static Matcher<Iterable<?>> equalOrCloseTo(List<?> list) {
        if (list == null || list.isEmpty()) return equalTo(list);
        List<Matcher<?>> matchers = list.stream().map(e -> e instanceof Double ? closeTo(((Double) e), 0.0001) : equalTo(e)).collect(Collectors.toList());
        return new IsIterableContainingInOrder(matchers);
    }
}
