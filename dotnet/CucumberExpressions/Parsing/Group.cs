using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace CucumberExpressions.Parsing;

public class Group
{
    public string Value { get; }
    public int Start { get; }
    public int End { get; }
    public List<Group> Children { get; }

    public Group(string value, int start, int end, List<Group> children)
    {
        Value = value;
        Start = start;
        End = end;
        Children = children;
    }

    public string[] GetValues()
    {
        if(Children == null) {
            return new string[]{ Value };
        }
        return Children.Select(g => g.Value).ToArray();
    }

    /**
     * Parse a {@link Pattern} into collection of {@link Group}s
     * 
     * @param expression the expression to decompose
     * @return A collection of {@link Group}s, possibly empty but never
     *         <code>null</code>
     */
    public static Group[] Parse(Regex expression)
    {
        GroupBuilder builder = TreeRegexp.CreateGroupBuilder(expression);
        return ToGroups(builder.Children).ToArray();
    }

    private static List<Group> ToGroups(IEnumerable<GroupBuilder> children)
    {
        var list = new List<Group>();
        if (children != null)
        {
            foreach (GroupBuilder child in children)
            {
                list.Add(new Group(child.Source, child.StartIndex, child.EndIndex,
                        ToGroups(child.Children)));
            }
        }
        return list;
    }
}
