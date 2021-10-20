using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using FluentAssertions;
using Xunit;
using Xunit.Abstractions;

namespace CucumberExpressions.Tests;

public class TreeRegexpTest {

    [Fact]
    public void exposes_group_source() {
        var tr = new TreeRegexp("(a(?:b)?)(c)");
        var list = new List<String>();
        foreach (GroupBuilder gb in tr.getGroupBuilder().getChildren()) {
            String source = gb.getSource();
            list.Add(source);
        }
        Assert.Equal(new[]{"a(?:b)?", "c"}, list);
    }

    [Fact]
    public void builds_tree() {
        var tr = new TreeRegexp("(a(b(c))(d))");
        var g = tr.match("abcd");
        Assert.Equal("abcd", g.getChildren()[0].getValue());
        Assert.Equal("bc", g.getChildren()[0].getChildren()[0].getValue());
        Assert.Equal("c", g.getChildren()[0].getChildren()[0].getChildren()[0].getValue());
        Assert.Equal("d", g.getChildren()[0].getChildren()[1].getValue());
    }

    [Fact]
    public void ignores_question_mark_colon_non_capturing_group() {
        var tr = new TreeRegexp("a(?:b)(c)");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void ignores_question_mark_exclamation_mark_non_capturing_group() {
        var tr = new TreeRegexp("a(?!b)(.+)");
        var g = tr.match("aBc");
        Assert.Equal("aBc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void ignores_question_mark_equal_sign_non_capturing_group() {
        var tr = new TreeRegexp("a(?=b)(.+)");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
        Assert.Equal("bc", g.getChildren()[0].getValue());
    }

    [Fact]
    public void ignores_question_mark_less_than_equal_sign_non_capturing_group() {
        var tr = new TreeRegexp("a(.+)(?<=c)$");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
        Assert.Equal("bc", g.getChildren()[0].getValue());
    }

    [Fact]
    public void ignores_question_mark_less_than_exclamation_mark_non_capturing_group() {
        var tr = new TreeRegexp("a(.+)(?<!b)$");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
        Assert.Equal("bc", g.getChildren()[0].getValue());
    }

    [Fact]
    public void ignores_question_mark_greater_then_non_capturing_group() {
        var tr = new TreeRegexp("a(?>b)(c)$");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
        Assert.Equal("c", g.getChildren()[0].getValue());
    }

    [Fact]
    public void matches_named_capturing_group() {
        var tr = new TreeRegexp("a(?<name>b)c$");
        var g = tr.match("abc");
        Assert.Equal("abc", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
        Assert.Equal("b", g.getChildren()[0].getValue());
    }

    [Fact]
    public void matches_optional_group() {
        var tr = new TreeRegexp("^Something( with an optional argument)?");
        var g = tr.match("Something");
        Assert.Null(g.getChildren()[0].getValue());
    }

    [Fact]
    public void matches_nested_groups() {
        var tr = new TreeRegexp("^A (\\d+) thick line from ((\\d+),\\s*(\\d+),\\s*(\\d+)) to ((\\d+),\\s*(\\d+),\\s*(\\d+))");
        var g = tr.match("A 5 thick line from 10,20,30 to 40,50,60");

        Assert.Equal("5", g.getChildren()[0].getValue());
        Assert.Equal("10,20,30", g.getChildren()[1].getValue());
        Assert.Equal("10", g.getChildren()[1].getChildren()[0].getValue());
        Assert.Equal("20", g.getChildren()[1].getChildren()[1].getValue());
        Assert.Equal("30", g.getChildren()[1].getChildren()[2].getValue());
        Assert.Equal("40,50,60", g.getChildren()[2].getValue());
        Assert.Equal("40", g.getChildren()[2].getChildren()[0].getValue());
        Assert.Equal("50", g.getChildren()[2].getChildren()[1].getValue());
        Assert.Equal("60", g.getChildren()[2].getChildren()[2].getValue());
    }

    [Fact]
    public void captures_non_capturing_groups_with_capturing_groups_inside() {
        var tr = new TreeRegexp("the stdout(?: from \"(.*?)\")?");
        var g = tr.match("the stdout");
        Assert.Equal("the stdout", g.getValue());
        Assert.Null(g.getChildren()[0].getValue());
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void detects_multiple_non_capturing_groups() {
        var tr = new TreeRegexp("(?:a)(:b)(\\?c)(d)");
        var g = tr.match("a:b?cd");
        Assert.Equal(3, g.getChildren().Count);
    }

    [Fact]
    public void works_with_escaped_backslash() {
        var tr = new TreeRegexp("foo\\\\(bar|baz)");
        var g = tr.match("foo\\bar");
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void works_with_slash_which_doesnt_need_escaping_in_java() {
        var tr = new TreeRegexp("^I go to '/(.+)'$");
        var g = tr.match("I go to '/hello'");
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void works_digit_and_word() {
        var tr = new TreeRegexp("^(\\d) (\\w+) (\\w+)$");
        var g = tr.match("2 you привет");
        Assert.Equal(3, g.getChildren().Count);
    }

    [Fact]
    public void captures_start_and_end() {
        var tr = new TreeRegexp("^the step \"([^\"]*)\" has status \"([^\"]*)\"$");
        var g = tr.match("the step \"a pending step\" has status \"pending\"");
        Assert.Equal(10, g.getChildren()[0].getStart());
        Assert.Equal(24, g.getChildren()[0].getEnd());
        Assert.Equal(38, g.getChildren()[1].getStart());
        Assert.Equal(45, g.getChildren()[1].getEnd());
    }

    [Fact]
    public void doesnt_consider_parenthesis_in_character_class_as_group() {
        var tr = new TreeRegexp("^drawings: ([A-Z_, ()]+)$");
        var g = tr.match("drawings: FU(BAR)");
        Assert.Equal("drawings: FU(BAR)", g.getValue());
        Assert.Equal("FU(BAR)", g.getChildren()[0].getValue());
        Assert.Equal(0, g.getChildren()[0].getChildren().Count);
    }

    [Fact]
    public void works_with_flags() {
        var tr = new TreeRegexp(new Regex("HELLO", RegexOptions.IgnoreCase));
        var g = tr.match("hello");
        Assert.Equal("hello", g.getValue());
    }

    [Fact]
    public void works_with_inline_flags() {
        var tr = new TreeRegexp(new Regex("(?i)HELLO"));
        var g = tr.match("hello");
        Assert.Equal("hello", g.getValue());
        Assert.Equal(0, g.getChildren().Count);
    }

    [Fact]
    public void works_with_non_capturing_inline_flags() {
        var tr = new TreeRegexp(new Regex("(?i:HELLO)"));
        var g = tr.match("hello");
        Assert.Equal("hello", g.getValue());
        Assert.Equal(0, g.getChildren().Count);
    }

    [Fact]
    public void empty_capturing_group() {
        var tr = new TreeRegexp(new Regex("()"));
        var g = tr.match("");
        Assert.Equal("", g.getValue());
        Assert.Equal(1, g.getChildren().Count);
    }

    [Fact]
    public void empty_non_capturing_group() {
        var tr = new TreeRegexp(new Regex("(?:)"));
        var g = tr.match("");
        Assert.Equal("", g.getValue());
        Assert.Equal(0, g.getChildren().Count);
    }

    [Fact]
    public void empty_look_ahead() {
        var tr = new TreeRegexp(new Regex("(?<=)"));
        var g = tr.match("");
        Assert.Equal("", g.getValue());
        Assert.Equal(0, g.getChildren().Count);
    }
}
