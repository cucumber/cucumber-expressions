using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using CucumberExpressions.Parsing;
using Xunit;

namespace CucumberExpressions.Tests;

public class TreeRegexpTest
{
    [Fact]
    public void exposes_group_source()
    {
        var tr = new TreeRegexp("(a(?:b)?)(c)");
        var list = new List<String>();
        foreach (GroupBuilder gb in tr.GroupBuilder.Children)
        {
            String source = gb.Source;
            list.Add(source);
        }
        Assert.Equal(new[] { "a(?:b)?", "c" }, list);
    }

    [Fact]
    public void builds_tree()
    {
        var tr = new TreeRegexp("(a(b(c))(d))");
        var g = tr.Match("abcd");
        Assert.Equal("abcd", g.Children[0].Value);
        Assert.Equal("bc", g.Children[0].Children[0].Value);
        Assert.Equal("c", g.Children[0].Children[0].Children[0].Value);
        Assert.Equal("d", g.Children[0].Children[1].Value);
    }

    [Fact]
    public void ignores_question_mark_colon_non_capturing_group()
    {
        var tr = new TreeRegexp("a(?:b)(c)");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
    }

    [Fact]
    public void ignores_question_mark_exclamation_mark_non_capturing_group()
    {
        var tr = new TreeRegexp("a(?!b)(.+)");
        var g = tr.Match("aBc");
        Assert.Equal("aBc", g.Value);
        Assert.Single(g.Children);
    }

    [Fact]
    public void ignores_question_mark_equal_sign_non_capturing_group()
    {
        var tr = new TreeRegexp("a(?=b)(.+)");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
        Assert.Equal("bc", g.Children[0].Value);
    }

    [Fact]
    public void ignores_question_mark_less_than_equal_sign_non_capturing_group()
    {
        var tr = new TreeRegexp("a(.+)(?<=c)$");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
        Assert.Equal("bc", g.Children[0].Value);
    }

    [Fact]
    public void ignores_question_mark_less_than_exclamation_mark_non_capturing_group()
    {
        var tr = new TreeRegexp("a(.+)(?<!b)$");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
        Assert.Equal("bc", g.Children[0].Value);
    }

    [Fact]
    public void ignores_question_mark_greater_then_non_capturing_group()
    {
        var tr = new TreeRegexp("a(?>b)(c)$");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
        Assert.Equal("c", g.Children[0].Value);
    }

    [Fact]
    public void matches_named_capturing_group()
    {
        var tr = new TreeRegexp("a(?<name>b)c$");
        var g = tr.Match("abc");
        Assert.Equal("abc", g.Value);
        Assert.Single(g.Children);
        Assert.Equal("b", g.Children[0].Value);
    }

    [Fact]
    public void matches_optional_group()
    {
        var tr = new TreeRegexp("^Something( with an optional argument)?");
        var g = tr.Match("Something");
        Assert.Null(g.Children[0].Value);
    }

    [Fact]
    public void matches_nested_groups()
    {
        var tr = new TreeRegexp("^A (\\d+) thick line from ((\\d+),\\s*(\\d+),\\s*(\\d+)) to ((\\d+),\\s*(\\d+),\\s*(\\d+))");
        var g = tr.Match("A 5 thick line from 10,20,30 to 40,50,60");

        Assert.Equal("5", g.Children[0].Value);
        Assert.Equal("10,20,30", g.Children[1].Value);
        Assert.Equal("10", g.Children[1].Children[0].Value);
        Assert.Equal("20", g.Children[1].Children[1].Value);
        Assert.Equal("30", g.Children[1].Children[2].Value);
        Assert.Equal("40,50,60", g.Children[2].Value);
        Assert.Equal("40", g.Children[2].Children[0].Value);
        Assert.Equal("50", g.Children[2].Children[1].Value);
        Assert.Equal("60", g.Children[2].Children[2].Value);
    }

    [Fact]
    public void captures_non_capturing_groups_with_capturing_groups_inside()
    {
        var tr = new TreeRegexp("the stdout(?: from \"(.*?)\")?");
        var g = tr.Match("the stdout");
        Assert.Equal("the stdout", g.Value);
        Assert.Null(g.Children[0].Value);
        Assert.Single(g.Children);
    }

    [Fact]
    public void detects_multiple_non_capturing_groups()
    {
        var tr = new TreeRegexp("(?:a)(:b)(\\?c)(d)");
        var g = tr.Match("a:b?cd");
        Assert.Equal(3, g.Children.Count);
    }

    [Fact]
    public void works_with_escaped_backslash()
    {
        var tr = new TreeRegexp("foo\\\\(bar|baz)");
        var g = tr.Match("foo\\bar");
        Assert.Single(g.Children);
    }

    [Fact]
    public void works_with_slash_which_doesnt_need_escaping_in_java()
    {
        var tr = new TreeRegexp("^I go to '/(.+)'$");
        var g = tr.Match("I go to '/hello'");
        Assert.Single(g.Children);
    }

    [Fact]
    public void works_digit_and_word()
    {
        var tr = new TreeRegexp("^(\\d) (\\w+) (\\w+)$");
        var g = tr.Match("2 you привет");
        Assert.Equal(3, g.Children.Count);
    }

    [Fact]
    public void captures_start_and_end()
    {
        var tr = new TreeRegexp("^the step \"([^\"]*)\" has status \"([^\"]*)\"$");
        var g = tr.Match("the step \"a pending step\" has status \"pending\"");
        Assert.Equal(10, g.Children[0].Start);
        Assert.Equal(24, g.Children[0].End);
        Assert.Equal(38, g.Children[1].Start);
        Assert.Equal(45, g.Children[1].End);
    }

    [Fact]
    public void doesnt_consider_parenthesis_in_character_class_as_group()
    {
        var tr = new TreeRegexp("^drawings: ([A-Z_, ()]+)$");
        var g = tr.Match("drawings: FU(BAR)");
        Assert.Equal("drawings: FU(BAR)", g.Value);
        Assert.Equal("FU(BAR)", g.Children[0].Value);
        Assert.Empty(g.Children[0].Children);
    }

    [Fact]
    public void works_with_flags()
    {
        var tr = new TreeRegexp(new Regex("HELLO", RegexOptions.IgnoreCase));
        var g = tr.Match("hello");
        Assert.Equal("hello", g.Value);
    }

    [Fact]
    public void works_with_inline_flags()
    {
        var tr = new TreeRegexp(new Regex("(?i)HELLO"));
        var g = tr.Match("hello");
        Assert.Equal("hello", g.Value);
        Assert.IsNull(g.Children);
    }

    [Fact]
    public void works_with_non_capturing_inline_flags()
    {
        var tr = new TreeRegexp(new Regex("(?i:HELLO)"));
        var g = tr.Match("hello");
        Assert.Equal("hello", g.Value);
        Assert.IsNull(g.Children);
    }

    [Fact]
    public void empty_capturing_group()
    {
        var tr = new TreeRegexp(new Regex("()"));
        var g = tr.Match("");
        Assert.Equal("", g.Value);
        Assert.Single(g.Children);
    }

    [Fact]
    public void empty_non_capturing_group()
    {
        var tr = new TreeRegexp(new Regex("(?:)"));
        var g = tr.Match("");
        Assert.Equal("", g.Value);
        Assert.IsNull(g.Children);
    }

    [Fact]
    public void empty_look_ahead()
    {
        var tr = new TreeRegexp(new Regex("(?<=)"));
        var g = tr.Match("");
        Assert.Equal("", g.Value);
        Assert.IsNull(g.Children);
    }
}
