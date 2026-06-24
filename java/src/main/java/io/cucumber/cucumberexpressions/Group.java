package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;
import org.jspecify.annotations.Nullable;

import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.util.Collections.singletonList;

import java.util.Collection;

@API(status = API.Status.STABLE)
public final class Group {
    private final @Nullable List<Group> children;
    private final @Nullable String value;
    private final int start;
    private final int end;

    Group(@Nullable String value, int start, int end, @Nullable List<Group> children) {
        this.value = value;
        this.start = start;
        this.end = end;
        this.children = children;
    }

    public @Nullable String getValue() {
        return value;
    }

    public int getStart() {
        return start;
    }

    public int getEnd() {
        return end;
    }

    /**
     * A groups children.
     *
     * <p>There are either one or more children or the value is absent.
     */
    public Optional<List<Group>> getChildren() {
        return Optional.ofNullable(children);
    }

    public List<@Nullable String> getValues() {
        return getChildren()
                .orElseGet(() -> singletonList(this))
                .stream()
                .map(Group::getValue)
                .collect(Collectors.toList());
    }

    /**
     * Parse a {@link Pattern} into collection of {@link Group}s
     * 
     * @param expression the expression to decompose
     * @return A collection of {@link Group}s, possibly empty but never
     *         <code>null</code>
     */
    public static Collection<Group> parse(Pattern expression) {
        return TreeRegexp.createGroupBuilder(expression).toGroups();
    }

}
