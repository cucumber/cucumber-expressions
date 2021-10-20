using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class GroupBuilder {
    private readonly List<GroupBuilder> groupBuilders = new();
    private bool capturing = true;
    private String source;
    private int startIndex;
    private int endIndex;

    public GroupBuilder(int startIndex) {
        this.startIndex = startIndex;
    }

    public void add(GroupBuilder groupBuilder) {
        groupBuilders.Add(groupBuilder);
    }

    public Group build(Match matcher, IEnumerator<int> groupIndices)
    {
        groupIndices.MoveNext();
        int groupIndex = groupIndices.Current;
        var children = new List<Group>(groupBuilders.Count);
        foreach (GroupBuilder childGroupBuilder in groupBuilders) {
            children.Add(childGroupBuilder.build(matcher, groupIndices));
        }

        var matcherGroup = matcher.Groups[groupIndex];
        return new Group(matcherGroup.Success ? matcherGroup.Value : null, matcherGroup.Index, matcherGroup.Index + matcherGroup.Length, children);
    }

    public void setNonCapturing() {
        this.capturing = false;
    }

    public bool isCapturing() {
        return capturing;
    }

    public void moveChildrenTo(GroupBuilder groupBuilder) {
        foreach (GroupBuilder child in groupBuilders) {
            groupBuilder.add(child);
        }
    }

    public List<GroupBuilder> getChildren() {
        return groupBuilders;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public int getStartIndex() {
        return startIndex;
    }

    public int getEndIndex() {
        return endIndex;
    }

    public void setEndIndex(int endIndex) {
        this.endIndex = endIndex;
    }
}
