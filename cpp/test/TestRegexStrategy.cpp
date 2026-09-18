#include "cucumber/cucumber-expressions/StdRegexStrategy.hpp"
#ifdef CCR_HAS_RE2
#include "cucumber/cucumber-expressions/Re2RegexStrategy.hpp"
#endif
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <stdexcept>
#include <string>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        template<typename T>
        struct TestRegexStrategy : testing::Test
        {};
    }

#ifdef CCR_HAS_RE2
    using RegexStrategyTypes = testing::Types<StdRegexStrategy, Re2RegexStrategy>;
#else
    using RegexStrategyTypes = testing::Types<StdRegexStrategy>;
#endif
    TYPED_TEST_SUITE(TestRegexStrategy, RegexStrategyTypes);

    TYPED_TEST(TestRegexStrategy, ReturnsNulloptWhenNoMatch)
    {
        TypeParam strategy{ R"__(hello)__" };

        EXPECT_THAT(strategy.Match("world"), testing::IsFalse());
    }

    TYPED_TEST(TestRegexStrategy, ReturnsVectorWhenPatternMatches)
    {
        TypeParam strategy{ R"__((\d+))__" };

        const auto result = strategy.Match("abc 42 def");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(0)->value, testing::StrEq("42")); // whole match
        EXPECT_THAT(result->at(1)->value, testing::StrEq("42")); // first capture group
    }

    TYPED_TEST(TestRegexStrategy, WholeMatchIsAtIndexZero)
    {
        TypeParam strategy{ R"__((\w+)\s+(\w+))__" };

        const auto result = strategy.Match("hello world");

        ASSERT_THAT(result, testing::IsTrue());
        ASSERT_THAT(result->size(), testing::Eq(3));
        EXPECT_THAT(result->at(0)->value, testing::StrEq("hello world")); // whole match
        EXPECT_THAT(result->at(1)->value, testing::StrEq("hello"));       // first capture group
        EXPECT_THAT(result->at(2)->value, testing::StrEq("world"));       // second capture group
    }

    TYPED_TEST(TestRegexStrategy, MatchesNegativeInteger)
    {
        TypeParam strategy{ R"__((-?\d+))__" };

        const auto result = strategy.Match("-22");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(1)->value, testing::StrEq("-22"));
    }

    TYPED_TEST(TestRegexStrategy, MatchesEmptyCapture)
    {
        TypeParam strategy{ R"__(^The value equals "([^"]*)"$)__" };

        const auto result = strategy.Match(R"__(The value equals "")__");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(1)->value, testing::StrEq(""));
    }

    TYPED_TEST(TestRegexStrategy, ReturnsStartPositionOfWholeMatch)
    {
        TypeParam strategy{ R"__((\d+))__" };

        const auto result = strategy.Match("abc 42 def");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(0)->start, testing::Eq(4)); // "42" starts at index 4
        EXPECT_THAT(result->at(0)->end, testing::Eq(6));   // "42" ends after index 6
    }

    TYPED_TEST(TestRegexStrategy, ReturnsStartPositionOfCaptureGroup)
    {
        TypeParam strategy{ R"__((\w+)\s+(\w+))__" };

        const auto result = strategy.Match("hello world");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(1)->start, testing::Eq(0)); // "hello" starts at 0
        EXPECT_THAT(result->at(1)->end, testing::Eq(5));   // "hello" ends at 5
        EXPECT_THAT(result->at(2)->start, testing::Eq(6)); // "world" starts at 6
        EXPECT_THAT(result->at(2)->end, testing::Eq(11));  // "world" ends at 11
    }

    TYPED_TEST(TestRegexStrategy, UnmatchedGroupIsNullopt)
    {
        TypeParam strategy{ R"__(^Something( with an optional argument)?)__" };

        const auto result = strategy.Match("Something");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(1), testing::IsFalse());
    }

#ifdef CCR_HAS_RE2
    TEST(Re2RegexStrategy, ThrowsOnInvalidPattern)
    {
        EXPECT_THROW(Re2RegexStrategy{ R"__([invalid)__" }, std::invalid_argument);
    }
#endif
}
