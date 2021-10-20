using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

/**
 * TreeRegexp represents matches as a tree of {@link Group}
 * reflecting the nested structure of capture groups in the original
 * regexp.
 */
public class TreeRegexp {
    public Regex pattern { get; }
    private readonly GroupBuilder groupBuilder;

    public TreeRegexp(String regexp) : this(new Regex(regexp))
    {
    }

    public TreeRegexp(Regex pattern) {
        this.pattern = pattern;
        this.groupBuilder = createGroupBuilder(pattern);
    }

    public static GroupBuilder createGroupBuilder(Regex pattern) {
        var source = pattern.ToString();
        var stack = new Stack<GroupBuilder>(new []{ new GroupBuilder(0)});
        bool escaping = false;
        bool charClass = false;

        for (int i = 0; i < source.Length; i++) {
            char c = source[i];
            if (c == '[' && !escaping) {
                charClass = true;
            } else if (c == ']' && !escaping) {
                charClass = false;
            } else if (c == '(' && !escaping && !charClass) {
                bool nonCapturing = isNonCapturingGroup(source, i);
                GroupBuilder groupBuilder = new GroupBuilder(i);
                if (nonCapturing) {
                    groupBuilder.setNonCapturing();
                }
                stack.Push(groupBuilder);
            } else if (c == ')' && !escaping && !charClass) {
                GroupBuilder gb = stack.Pop();
                if (gb.isCapturing()) {
                    var startIndex = gb.getStartIndex() + 1;
                    gb.setSource(source.Substring(startIndex, i - startIndex));
                    stack.Peek().add(gb);
                } else {
                    gb.moveChildrenTo(stack.Peek());
                }
                gb.setEndIndex(i);
            }
            escaping = c == '\\' && !escaping;
        }
        return stack.Pop();
    }

    private static bool isNonCapturingGroup(String source, int i) {
        // Regex is valid. Bounds check not required.
        if (source[i+1] != '?') {
            // (X)
            return false;
        }
        if (source[i+2] != '<') {
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

    

    public Group match(string s) {
        var matcher = pattern.Match(s);
        if (!matcher.Success)
            return null;
        return groupBuilder.build(matcher, Enumerable.Range(0, matcher.Groups.Count).GetEnumerator());
    }

    public GroupBuilder getGroupBuilder() {
        return groupBuilder;
    }

}
