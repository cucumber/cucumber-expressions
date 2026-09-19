
#include "cucumber/cucumber-expressions/TreeRegexp.hpp"
#include "gmock/gmock.h"
#include <gtest/gtest.h>
#include <iterator>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    using namespace std::string_view_literals;

    namespace
    {
        std::string_view BuilderPattern(const GroupBuilder& builder)
        {
            return builder.Pattern();
        }
    }

    TEST(TestTreeRegexp, exposes_group_source)
    {
        TreeRegexp treeRegexp{ R"__((a(?:b)?)(c))__" };
        EXPECT_THAT(treeRegexp.RootBuilder().Children().begin()->Pattern(), testing::StrEq("a(?:b)?"sv));
        EXPECT_THAT(std::next(treeRegexp.RootBuilder().Children().begin())->Pattern(), testing::StrEq("c"sv));
    }

    TEST(TestTreeRegexp, builds_tree)
    {
        TreeRegexp treeRegexp{ R"__((a(?:b)?)(c))__" };
        const auto group = *treeRegexp.MatchToGroup("ac");
        EXPECT_THAT(group.value.value(), testing::StrEq("ac"));
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("a"));
        EXPECT_THAT(group.children[0].children.empty(), testing::IsTrue());
        EXPECT_THAT(group.children[1].value.value(), testing::StrEq("c"));
    }

    TEST(TestTreeRegexp, ignores_non_capture_group_as_a_non_capturing_group)
    {
        TreeRegexp treeRegexp{ R"__(a(?:b)(c))__" };
        const auto group = *treeRegexp.MatchToGroup("abc");
        EXPECT_THAT(group.value.value(), testing::StrEq("abc"));
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, ignores_negative_lookahead_as_a_non_capturing_group)
    {
        TreeRegexp treeRegexp{ R"__(a(?!b)(.+))__" };
        const auto group = *treeRegexp.MatchToGroup("aBc");
        EXPECT_THAT(group.value.value(), testing::StrEq("aBc"));
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, ignores_positive_lookahead_as_a_non_capturing_group)
    {
        TreeRegexp treeRegexp{ R"__(a(?=[b])(.+))__" };
        const auto group = *treeRegexp.MatchToGroup("abc");
        EXPECT_THAT(group.value.value(), testing::StrEq("abc"));
        EXPECT_THAT(group.children.size(), 1);
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("bc"));
    }

    TEST(TestTreeRegexp, DISABLED_ignores_positive_lookbehind_as_a_non_capturing_group)
    {
        // std::regex does not support positive lookbehind
        TreeRegexp treeRegexp{ R"__(a(.+)(?<=c)$)__" };
        const auto group = *treeRegexp.MatchToGroup("abc");
        EXPECT_THAT(group.value.value(), testing::StrEq("abc"));
        EXPECT_THAT(group.children.size(), 1);
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("bc"));
    }

    TEST(TestTreeRegexp, DISABLED_ignores_negative_lookbehind_as_a_non_capturing_group)
    {
        // std::regex does not support negative lookbehind
        TreeRegexp treeRegexp{ R"__(a(.+?)(?<!b)$)__" };
        const auto group = *treeRegexp.MatchToGroup("abc");
        EXPECT_THAT(group.value.value(), testing::StrEq("abc"));
        EXPECT_THAT(group.children.size(), 1);
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("bc"));
    }

    TEST(TestTreeRegexp, DISABLED_matches_named_capturing_group)
    {
        // std::regex does not support named capturing groups
        TreeRegexp treeRegexp{ R"__(a(?<name>b)c)__" };
        const auto group = *treeRegexp.MatchToGroup("abc");
        EXPECT_THAT(group.value.value(), testing::StrEq("abc"));
        EXPECT_THAT(group.children.size(), 1);
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("b"));
    }

    TEST(TestTreeRegexp, matches_optional_group)
    {
        TreeRegexp treeRegexp{ R"__(^Something( with an optional argument)?)__" };
        const auto group = *treeRegexp.MatchToGroup("Something");
        EXPECT_THAT(group.children[0].value, testing::IsFalse());
    }

    TEST(TestTreeRegexp, matches_nested_groups)
    {
        TreeRegexp treeRegexp{ R"__(^A (\d+) thick line from ((\d+),\s*(\d+),\s*(\d+)) to ((\d+),\s*(\d+),\s*(\d+)))__" };
        const auto group = *treeRegexp.MatchToGroup("A 5 thick line from 10,20,30 to 40,50,60");
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("5"));
        EXPECT_THAT(group.children[1].value.value(), testing::StrEq("10,20,30"));
        EXPECT_THAT(group.children[1].children[0].value.value(), testing::StrEq("10"));
        EXPECT_THAT(group.children[1].children[1].value.value(), testing::StrEq("20"));
        EXPECT_THAT(group.children[1].children[2].value.value(), testing::StrEq("30"));
        EXPECT_THAT(group.children[2].value.value(), testing::StrEq("40,50,60"));
        EXPECT_THAT(group.children[2].children[0].value.value(), testing::StrEq("40"));
        EXPECT_THAT(group.children[2].children[1].value.value(), testing::StrEq("50"));
        EXPECT_THAT(group.children[2].children[2].value.value(), testing::StrEq("60"));
    }

    TEST(TestTreeRegexp, detects_multiple_non_capturing_groups)
    {
        TreeRegexp treeRegexp{ R"__((?:a)(:b)(\?c)(d))__" };
        const auto group = *treeRegexp.MatchToGroup("a:b?cd");
        EXPECT_THAT(group.children.size(), testing::Eq(3));
    }

    TEST(TestTreeRegexp, works_with_escaped_backslash)
    {
        TreeRegexp treeRegexp{ R"__(foo\\(bar|baz))__" };
        const auto group = *treeRegexp.MatchToGroup("foo\\bar");
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, works_with_escaped_slash)
    {
        TreeRegexp treeRegexp{ R"__(^I go to '\/(.+)'$)__" };
        const auto group = *treeRegexp.MatchToGroup("I go to '/hello'");
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, works_with_digit_and_word)
    {
        TreeRegexp treeRegexp{ R"__(^(\d) (\w+)$)__" };
        const auto group = *treeRegexp.MatchToGroup("2 you");
        EXPECT_THAT(group.children.size(), testing::Eq(2));
    }

    TEST(TestTreeRegexp, captures_non_capturing_groups_with_capturing_groups_inside)
    {
        TreeRegexp treeRegexp{ R"__(the stdout(?: from "(.*?)")?)__" };
        const auto group = *treeRegexp.MatchToGroup("the stdout");

        EXPECT_THAT(group.value.value(), testing::StrEq("the stdout"));
        EXPECT_THAT(group.children[0].value, testing::IsFalse());
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, DISABLED_works_with_case_insensitive_flag)
    {
        // std::regex does not support inline case insensitive flag
        TreeRegexp treeRegexp{ R"__(HELLO/i)__" };
        const auto group = *treeRegexp.MatchToGroup("hello");
        EXPECT_THAT(group.value.value(), testing::StrEq("hello"));
    }

    TEST(TestTreeRegexp, empty_capturing_group)
    {
        TreeRegexp treeRegexp{ R"__(())__" };
        const auto group = *treeRegexp.MatchToGroup("");
        EXPECT_THAT(group.value.value(), testing::StrEq(""));
        EXPECT_THAT(group.children.size(), testing::Eq(1));
    }

    TEST(TestTreeRegexp, DISABLED_empty_look_ahead)
    {
        // std::regex does not support positive lookbehind
        TreeRegexp treeRegexp{ R"__((?<=))__" };
        const auto group = *treeRegexp.MatchToGroup("");
        EXPECT_THAT(group.value.value(), testing::StrEq(""));
        EXPECT_THAT(group.children.size(), testing::Eq(0));
    }

    TEST(TestTreeRegexp, does_not_consider_parenthesis_in_character_class_as_group)
    {
        TreeRegexp treeRegexp{ R"__(^drawings: ([A-Z, ()]+)$)__" };
        const auto group = *treeRegexp.MatchToGroup("drawings: ONE(TWO)");
        EXPECT_THAT(group.value.value(), testing::StrEq("drawings: ONE(TWO)"));
        EXPECT_THAT(group.children.size(), testing::Eq(1));
        EXPECT_THAT(group.children[0].value.value(), testing::StrEq("ONE(TWO)"));
    }
}
