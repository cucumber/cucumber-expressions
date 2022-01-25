import re

from cucumber_expressions.tree_regexp import TreeRegexp


class TestTreeRegexp:
    @staticmethod
    def test_exposes_group_source():
        tr = TreeRegexp("(a(?:b)?)(c)")
        _list = [gb.source for gb in tr.group_builder.children]
        assert ["a(?:b)?", "c"] == _list

    @staticmethod
    def test_builds_tree():
        tr = TreeRegexp("(a(b(c))(d))")
        g = tr.match("abcd")
        assert "abcd" == g.children[0].value
        assert "bc" == g.children[0].children[0].value
        assert "c" == g.children[0].children[0].children[0].value
        assert "d" == g.children[0].children[1].value

    @staticmethod
    def test_ignores_question_mark_colon_non_capturing_group():
        tr = TreeRegexp("a(?:b)(c)")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 1 == len(g.children)

    @staticmethod
    def test_ignores_question_mark_exclamation_mark_non_capturing_group():
        tr = TreeRegexp("a(?!b)(.+)")
        g = tr.match("aBc")
        assert "aBc" == g.value
        assert 1 == len(g.children)

    def test_ignores_question_mark_equal_sign_non_capturing_group(self):
        tr = TreeRegexp("a(?=b)(.+)")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 1 == len(g.children)
        assert "bc" == g.children[0].value

    def test_ignores_question_mark_less_than_equal_sign_non_capturing_group(self):
        tr = TreeRegexp("a(.+)(?<=c)$")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 1 == len(g.children)
        assert "bc" == g.children[0].value

    def test_ignores_question_mark_less_than_exclamation_mark_non_capturing_group(self):
        tr = TreeRegexp("a(.+)(?<!b)$")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 1 == len(g.children)
        assert "bc" == g.children[0].value

    def test_ignores_atomic_non_capturing_group(self):
        tr = TreeRegexp("a(?=(?P<tmp>b))(?P=tmp)c")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 0 == len(g.children)

    def test_matches_named_capturing_group(self):
        tr = TreeRegexp("a(?P<name>b)c$")
        g = tr.match("abc")
        assert "abc" == g.value
        assert 0 == len(g.children)

    def test_matches_optional_group(self):
        tr = TreeRegexp("^Something( with an optional argument)?")
        g = tr.match("Something")
        assert g.children[0].value is None

    def test_matches_nested_groups(self):
        tr = TreeRegexp(
            "^A (\\d+) thick line from ((\\d+),\\s*(\\d+),\\s*(\\d+)) to ((\\d+),\\s*(\\d+),\\s*(\\d+))"
        )
        g = tr.match("A 5 thick line from 10,20,30 to 40,50,60")

        assert "5" == g.children[0].value
        assert "10,20,30" == g.children[1].value
        assert "10" == g.children[1].children[0].value
        assert "20" == g.children[1].children[1].value
        assert "30" == g.children[1].children[2].value
        assert "40,50,60" == g.children[2].value
        assert "40" == g.children[2].children[0].value
        assert "50" == g.children[2].children[1].value
        assert "60" == g.children[2].children[2].value

    def test_captures_non_capturing_groups_with_capturing_groups_inside(self):
        tr = TreeRegexp('the stdout(?: from "(.*?)")?')
        g = tr.match("the stdout")
        assert "the stdout" == g.value
        assert g.children[0].value is None
        assert 1 == len(g.children)

    def test_detects_multiple_non_capturing_groups(self):
        tr = TreeRegexp("(?:a)(:b)(\\?c)(d)")
        g = tr.match("a:b?cd")
        assert 3 == len(g.children)

    def test_works_with_escaped_backslash(self):
        tr = TreeRegexp("foo\\\\(bar|baz)")
        g = tr.match("foo\\bar")
        assert 1 == len(g.children)

    def test_works_with_slash_which_doesnt_need_escaping_in_java(self):
        tr = TreeRegexp("^I go to '/(.+)'$")
        g = tr.match("I go to '/hello'")
        assert 1 == len(g.children)

    def test_works_digit_and_word(self):
        tr = TreeRegexp("^(\\d) (\\w+) (\\w+)$")
        g = tr.match("2 you привет")
        assert 3 == len(g.children)

    def test_captures_start_and_end(self):
        tr = TreeRegexp('^the step "([^"]*)" has status "([^"]*)"$')
        g = tr.match('the step "a pending step" has status "pending"')
        assert 10 == g.children[0].start
        assert 24 == g.children[0].end
        assert 38 == g.children[1].start
        assert 45 == g.children[1].end

    def test_doesnt_consider_parenthesis_in_character_class_as_group(self):
        tr = TreeRegexp("^drawings: ([A-Z_, ()]+)$")
        g = tr.match("drawings: FU(BAR)")
        assert "drawings: FU(BAR)" == g.value
        assert "FU(BAR)" == g.children[0].value
        assert 0 == len(g.children[0].children)

    def test_works_with_flags(self):
        tr = TreeRegexp(re.compile(r"HELLO", re.IGNORECASE))
        g = tr.match("hello")
        assert "hello" == g.value

    def test_works_with_inline_flags(self):
        tr = TreeRegexp(re.compile(r"(?i)HELLO"))
        g = tr.match("hello")
        assert "hello" == g.value
        assert 0 == len(g.children)

    def test_works_with_non_capturing_inline_flags(self):
        tr = TreeRegexp(re.compile(r"(?i:HELLO)"))
        g = tr.match("hello")
        assert "hello" == g.value
        assert 0 == len(g.children)

    def test_empty_capturing_group(self):
        tr = TreeRegexp(re.compile(r"()"))
        g = tr.match("")
        assert "" == g.value
        assert 1 == len(g.children)

    def test_empty_non_capturing_group(self):
        tr = TreeRegexp(re.compile("(?:)"))
        g = tr.match("")
        assert "" == g.value
        assert 0 == len(g.children)

    def test_empty_look_ahead(self):
        tr = TreeRegexp(re.compile(r"(?<=)"))
        g = tr.match("")
        assert "" == g.value
        assert 0 == len(g.children)
