defmodule Varar.CucumberExpressions.TreeRegexpTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{Error, TreeRegexp}

  test "exposes the group source" do
    tr = TreeRegexp.new!(~r/(a(?:b)?)(c)/)
    assert Enum.map(tr.group_builder.children, & &1.source) == ["a(?:b)?", "c"]
  end

  test "builds a tree" do
    tr = TreeRegexp.new!(~r/(a(?:b)?)(c)/)
    group = TreeRegexp.match(tr, "ac")
    assert group.value == "ac"
    assert Enum.at(group.children, 0).value == "a"
    assert Enum.at(group.children, 0).children == nil
    assert Enum.at(group.children, 1).value == "c"
  end

  test "ignores `?:` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(?:b)(c)/)
    group = TreeRegexp.match(tr, "abc")
    assert group.value == "abc"
    assert length(group.children) == 1
    assert Enum.at(group.children, 0).value == "c"
  end

  test "ignores `?!` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(?!b)(.+)/)
    group = TreeRegexp.match(tr, "aBc")
    assert group.value == "aBc"
    assert length(group.children) == 1
  end

  test "ignores `?=` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(?=b)(.+)$/)
    group = TreeRegexp.match(tr, "abc")
    assert group.value == "abc"
    assert Enum.at(group.children, 0).value == "bc"
    assert length(group.children) == 1
  end

  test "ignores `?<=` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(.+)(?<=c)$/)
    group = TreeRegexp.match(tr, "abc")
    assert group.value == "abc"
    assert Enum.at(group.children, 0).value == "bc"
    assert length(group.children) == 1
  end

  test "ignores `?<!` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(.+)(?<!b)$/)
    group = TreeRegexp.match(tr, "abc")
    assert group.value == "abc"
    assert Enum.at(group.children, 0).value == "bc"
    assert length(group.children) == 1
  end

  test "ignores `?>` as a non-capturing group" do
    tr = TreeRegexp.new!(~r/a(?>b)c/)
    group = TreeRegexp.match(tr, "abc")
    assert group.value == "abc"
    assert group.children == nil
  end

  test "raises for named capture groups" do
    assert_raise Error, ~r/Named capture groups are not supported/, fn ->
      TreeRegexp.new!("^I am a person( named \"(?<first_name>.+) (?<last_name>.+)\")?$")
    end
  end

  test "matches an optional group" do
    tr = TreeRegexp.new!(~r/^Something( with an optional argument)?/)
    group = TreeRegexp.match(tr, "Something")
    assert Enum.at(group.children, 0).value == nil
  end

  test "matches nested groups" do
    tr =
      TreeRegexp.new!(
        ~r/^A (\d+) thick line from ((\d+),\s*(\d+),\s*(\d+)) to ((\d+),\s*(\d+),\s*(\d+))/
      )

    group = TreeRegexp.match(tr, "A 5 thick line from 10,20,30 to 40,50,60")

    assert Enum.at(group.children, 0).value == "5"
    assert Enum.at(group.children, 1).value == "10,20,30"
    assert Enum.map(Enum.at(group.children, 1).children, & &1.value) == ["10", "20", "30"]
    assert Enum.at(group.children, 2).value == "40,50,60"
    assert Enum.map(Enum.at(group.children, 2).children, & &1.value) == ["40", "50", "60"]
  end

  test "detects multiple non-capturing groups" do
    tr = TreeRegexp.new!(~r/(?:a)(:b)(\?c)(d)/)
    group = TreeRegexp.match(tr, "a:b?cd")
    assert length(group.children) == 3
  end

  test "works with escaped backslashes" do
    tr = TreeRegexp.new!(~r/foo\\(bar|baz)/)
    group = TreeRegexp.match(tr, "foo\\bar")
    assert length(group.children) == 1
  end

  test "works with escaped slashes" do
    tr = TreeRegexp.new!(~r/^I go to '\/(.+)'$/)
    group = TreeRegexp.match(tr, "I go to '/hello'")
    assert length(group.children) == 1
  end

  test "works with digit and word regexp metacharacters" do
    tr = TreeRegexp.new!(~r/^(\d) (\w+)$/)
    group = TreeRegexp.match(tr, "2 you")
    assert length(group.children) == 2
  end

  test "captures non-capturing groups with capturing groups inside" do
    tr = TreeRegexp.new!(~r/the stdout(?: from "(.*?)")?/)
    group = TreeRegexp.match(tr, "the stdout")
    assert group.value == "the stdout"
    assert Enum.at(group.children, 0).value == nil
    assert length(group.children) == 1
  end

  test "works with flags" do
    tr = TreeRegexp.new!(~r/HELLO/i)
    group = TreeRegexp.match(tr, "hello")
    assert group.value == "hello"
  end

  test "does not consider parentheses in regexp character classes as a group" do
    tr = TreeRegexp.new!(~r/^drawings: ([A-Z_, ()]+)$/)
    group = TreeRegexp.match(tr, "drawings: ONE, TWO(ABC)")
    assert group.value == "drawings: ONE, TWO(ABC)"
    assert Enum.at(group.children, 0).value == "ONE, TWO(ABC)"
    assert length(group.children) == 1
  end

  test "works with inline flags" do
    tr = TreeRegexp.new!("(?i)HELLO")
    group = TreeRegexp.match(tr, "hello")
    assert group.value == "hello"
    assert group.children == nil
  end

  test "works with non-capturing inline flags" do
    tr = TreeRegexp.new!("(?i:HELLO)")
    group = TreeRegexp.match(tr, "hello")
    assert group.value == "hello"
    assert group.children == nil
  end

  test "works with empty capturing groups" do
    tr = TreeRegexp.new!(~r/()/)
    group = TreeRegexp.match(tr, "")
    assert group.value == ""
    assert Enum.at(group.children, 0).value == ""
    assert length(group.children) == 1
  end

  test "works with empty non-capturing groups" do
    tr = TreeRegexp.new!(~r/(?:)/)
    group = TreeRegexp.match(tr, "")
    assert group.value == ""
    assert group.children == nil
  end

  test "works with empty non-look ahead groups" do
    tr = TreeRegexp.new!(~r/(?<=)/)
    group = TreeRegexp.match(tr, "")
    assert group.value == ""
    assert group.children == nil
  end
end
