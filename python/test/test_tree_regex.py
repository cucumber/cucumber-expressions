import re

from cucumber_expressions.tree_regexp import TreeRegexp


class TestTreeRegexp:
    @staticmethod
    def test_exposes_group_source():
        tree_regexp = TreeRegexp("(a(?:b)?)(c)")
        _list = [gb.source for gb in tree_regexp.group_builder.children]
        assert ["a(?:b)?", "c"] == _list

    @staticmethod
    def test_builds_tree_regexpee():
        tree_regexp = TreeRegexp("(a(b(c))(d))")
        group = tree_regexp.match("abcd")
        assert "abcd" == group.children[0].value
        assert "bc" == group.children[0].children[0].value
        assert "c" == group.children[0].children[0].children[0].value
        assert "d" == group.children[0].children[1].value

    @staticmethod
    def test_ignores_question_mark_colon_non_capturing_group():
        tree_regexp = TreeRegexp("a(?:b)(c)")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 1 == len(group.children)

    @staticmethod
    def test_ignores_question_mark_exclamation_mark_non_capturing_group():
        tree_regexp = TreeRegexp("a(?!b)(.+)")
        group = tree_regexp.match("aBc")
        assert "aBc" == group.value
        assert 1 == len(group.children)

    def test_ignores_question_mark_equal_sign_non_capturing_group(self):
        tree_regexp = TreeRegexp("a(?=b)(.+)")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 1 == len(group.children)
        assert "bc" == group.children[0].value

    def test_ignores_question_mark_less_than_equal_sign_non_capturing_group(self):
        tree_regexp = TreeRegexp("a(.+)(?<=c)$")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 1 == len(group.children)
        assert "bc" == group.children[0].value

    def test_ignores_question_mark_less_than_exclamation_mark_non_capturing_group(self):
        tree_regexp = TreeRegexp("a(.+)(?<!b)$")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 1 == len(group.children)
        assert "bc" == group.children[0].value

    def test_ignores_atomic_non_capturing_group(self):
        tree_regexp = TreeRegexp("a(?=(?P<tmp>b))(?P=tmp)c")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 0 == len(group.children)

    def test_matches_named_capturing_group(self):
        tree_regexp = TreeRegexp("a(?P<name>b)c$")
        group = tree_regexp.match("abc")
        assert "abc" == group.value
        assert 0 == len(group.children)

    def test_matches_optional_group(self):
        tree_regexp = TreeRegexp("^Something( with an optional argument)?")
        group = tree_regexp.match("Something")
        assert group.children[0].value is None

    def test_matches_nested_groups(self):
        tree_regexp = TreeRegexp(
            "^A (\\d+) thick line from ((\\d+),\\s*(\\d+),\\s*(\\d+)) to ((\\d+),\\s*(\\d+),\\s*(\\d+))"
        )
        group = tree_regexp.match("A 5 thick line from 10,20,30 to 40,50,60")

        assert "5" == group.children[0].value
        assert "10,20,30" == group.children[1].value
        assert "10" == group.children[1].children[0].value
        assert "20" == group.children[1].children[1].value
        assert "30" == group.children[1].children[2].value
        assert "40,50,60" == group.children[2].value
        assert "40" == group.children[2].children[0].value
        assert "50" == group.children[2].children[1].value
        assert "60" == group.children[2].children[2].value

    def test_captures_non_capturing_groups_with_capturing_groups_inside(self):
        tree_regexp = TreeRegexp('the stdout(?: from "(.*?)")?')
        group = tree_regexp.match("the stdout")
        assert "the stdout" == group.value
        assert group.children[0].value is None
        assert 1 == len(group.children)

    def test_detects_multiple_non_capturing_groups(self):
        tree_regexp = TreeRegexp("(?:a)(:b)(\\?c)(d)")
        group = tree_regexp.match("a:b?cd")
        assert 3 == len(group.children)

    def test_works_with_escaped_backslash(self):
        tree_regexp = TreeRegexp("foo\\\\(bar|baz)")
        group = tree_regexp.match("foo\\bar")
        assert 1 == len(group.children)

    def test_works_with_slash_which_doesnt_need_escaping_in_java(self):
        tree_regexp = TreeRegexp("^I go to '/(.+)'$")
        group = tree_regexp.match("I go to '/hello'")
        assert 1 == len(group.children)

    def test_works_digit_and_word(self):
        tree_regexp = TreeRegexp("^(\\d) (\\w+) (\\w+)$")
        group = tree_regexp.match("2 you привет")
        assert 3 == len(group.children)

    def test_captures_start_and_end(self):
        tree_regexp = TreeRegexp('^the step "([^"]*)" has status "([^"]*)"$')
        group = tree_regexp.match('the step "a pending step" has status "pending"')
        assert 10 == group.children[0].start
        assert 24 == group.children[0].end
        assert 38 == group.children[1].start
        assert 45 == group.children[1].end

    def test_doesnt_consider_parenthesis_in_character_class_as_group(self):
        tree_regexp = TreeRegexp("^drawings: ([A-Z_, ()]+)$")
        group = tree_regexp.match("drawings: FU(BAR)")
        assert "drawings: FU(BAR)" == group.value
        assert "FU(BAR)" == group.children[0].value
        assert 0 == len(group.children[0].children)

    def test_works_with_flags(self):
        tree_regexp = TreeRegexp(re.compile(r"HELLO", re.IGNORECASE))
        group = tree_regexp.match("hello")
        assert "hello" == group.value

    def test_works_with_inline_flags(self):
        tree_regexp = TreeRegexp(re.compile(r"(?i)HELLO"))
        group = tree_regexp.match("hello")
        assert "hello" == group.value
        assert 0 == len(group.children)

    def test_works_with_non_capturing_inline_flags(self):
        tree_regexp = TreeRegexp(re.compile(r"(?i:HELLO)"))
        group = tree_regexp.match("hello")
        assert "hello" == group.value
        assert 0 == len(group.children)

    def test_empty_capturing_group(self):
        tree_regexp = TreeRegexp(re.compile(r"()"))
        group = tree_regexp.match("")
        assert "" == group.value
        assert 1 == len(group.children)

    def test_empty_non_capturing_group(self):
        tree_regexp = TreeRegexp(re.compile("(?:)"))
        group = tree_regexp.match("")
        assert "" == group.value
        assert 0 == len(group.children)

    def test_empty_look_ahead(self):
        tree_regexp = TreeRegexp(re.compile(r"(?<=)"))
        group = tree_regexp.match("")
        assert "" == group.value
        assert 0 == len(group.children)
