package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.util.Collections.singletonList;

import java.util.Collection;

@API(status = API.Status.STABLE)
public class Group {
    private final List<Group> children;
    private final String value;
    private final int start;
    private final int end;

    Group(String value, int start, int end, List<Group> children) {
        this.value = value;
        this.start = start;
        this.end = end;
        this.children = children;
    }

    public String getValue() {
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

    public List<String> getValues() {
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
