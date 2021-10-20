using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class Group {
    private readonly List<Group> children;
    private readonly String value;
    private readonly int start;
    private readonly int end;

    public Group(String value, int start, int end, List<Group> children) {
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

    public List<Group> getChildren() {
        return children;
    }

    public List<String> getValues() {
        List<Group> groups = !getChildren().Any() ? 
            new List<Group> { this } : getChildren();
        return groups.Select(g => g.getValue()).ToList();
    }

    /**
     * Parse a {@link Pattern} into collection of {@link Group}s
     * 
     * @param expression the expression to decompose
     * @return A collection of {@link Group}s, possibly empty but never
     *         <code>null</code>
     */
    public static List<Group> parse(Regex expression) {
        GroupBuilder builder = TreeRegexp.createGroupBuilder(expression);
        return toGroups(builder.getChildren());
    }

    private static List<Group> toGroups(List<GroupBuilder> children) {
        var list = new List<Group>();
        if (children != null) {
            foreach (GroupBuilder child in children) {
                list.Add(new Group(child.getSource(), child.getStartIndex(), child.getEndIndex(),
                        toGroups(child.getChildren())));
            }
        }
        return list;
    }
}
