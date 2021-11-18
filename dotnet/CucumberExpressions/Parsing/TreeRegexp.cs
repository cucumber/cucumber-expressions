using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace CucumberExpressions.Parsing;

/**
 * TreeRegexp represents matches as a tree of {@link Group}
 * reflecting the nested structure of capture groups in the original
 * regexp.
 */
public class TreeRegexp
{
    public Regex Regex { get; }
    public GroupBuilder GroupBuilder { get; }

    public TreeRegexp(string regexp) : this(new Regex(regexp))
    {
    }

    public TreeRegexp(Regex regex)
    {
        Regex = regex;
        GroupBuilder = CreateGroupBuilder(regex);
    }

    public static GroupBuilder CreateGroupBuilder(Regex pattern)
    {
        var source = pattern.ToString();
        var stack = new Stack<GroupBuilder>(new[] { new GroupBuilder(0) });
        bool escaping = false;
        bool charClass = false;

        for (int i = 0; i < source.Length; i++)
        {
            char c = source[i];
            if (c == '[' && !escaping)
            {
                charClass = true;
            }
            else if (c == ']' && !escaping)
            {
                charClass = false;
            }
            else if (c == '(' && !escaping && !charClass)
            {
                bool nonCapturing = IsNonCapturingGroup(source, i);
                GroupBuilder groupBuilder = new GroupBuilder(i);
                if (nonCapturing)
                {
                    groupBuilder.SetNonCapturing();
                }
                stack.Push(groupBuilder);
            }
            else if (c == ')' && !escaping && !charClass)
            {
                GroupBuilder gb = stack.Pop();
                if (gb.IsCapturing)
                {
                    var startIndex = gb.StartIndex + 1;
                    gb.Source = source.Substring(startIndex, i - startIndex);
                    stack.Peek().Add(gb);
                }
                else
                {
                    gb.MoveChildrenTo(stack.Peek());
                }
                gb.EndIndex = i;
            }
            escaping = c == '\\' && !escaping;
        }
        return stack.Pop();
    }

    private static bool IsNonCapturingGroup(string source, int i)
    {
        // Regex is valid. Bounds check not required.
        if (source[i + 1] != '?')
        {
            // (X)
            return false;
        }
        if (source[i + 2] != '<')
        {
            // (?:X)
            // (?idmsuxU-idmsuxU)
            // (?idmsux-idmsux:X)
            // (?=X)
            // (?!X)
            // (?>X)
            return true;
        }
        // (?<=X) or (?<!X) else (?<name>X)
        return source[i + 3] == '=' || source[i + 3] == '!';
    }

    public Group Match(string s)
    {
        var matcher = Regex.Match(s);
        if (!matcher.Success)
            return null;
        return GroupBuilder.Build(matcher, Enumerable.Range(0, matcher.Groups.Count).GetEnumerator());
    }
}
