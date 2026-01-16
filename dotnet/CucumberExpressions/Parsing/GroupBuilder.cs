using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace CucumberExpressions.Parsing;

public class GroupBuilder
{
    private readonly List<GroupBuilder> _groupBuilders = new();

    public string Source { get; set; }

    public int StartIndex { get; }

    public int EndIndex { get; set; }

    public bool IsCapturing { get; private set; } = true;

    public IEnumerable<GroupBuilder> Children => _groupBuilders;

    public GroupBuilder(int startIndex)
    {
        StartIndex = startIndex;
    }

    public void Add(GroupBuilder groupBuilder)
    {
        _groupBuilders.Add(groupBuilder);
    }

    public Group Build(Match matcher, IEnumerator<int> groupIndices)
    {
        groupIndices.MoveNext();
        int groupIndex = groupIndices.Current;
        var children = new List<Group>(_groupBuilders.Count);
        foreach (GroupBuilder childGroupBuilder in _groupBuilders)
        {
            children.Add(childGroupBuilder.Build(matcher, groupIndices));
        }

        var matcherGroup = matcher.Groups[groupIndex];
        return new Group(
            matcherGroup.Success ? matcherGroup.Value : null, 
            matcherGroup.Index, 
            matcherGroup.Index + matcherGroup.Length, 
            children.Any() ? children : null
        );
    }

    public void SetNonCapturing()
    {
        IsCapturing = false;
    }

    public void MoveChildrenTo(GroupBuilder groupBuilder)
    {
        foreach (GroupBuilder child in _groupBuilders)
        {
            groupBuilder.Add(child);
        }
    }
}
