#include "cucumber/cucumber-expressions/RegexStrategyFactory.hpp"
#include "cucumber/cucumber-expressions/StdRegexStrategy.hpp"
#ifdef CCR_HAS_RE2
#include "cucumber/cucumber-expressions/Re2RegexStrategy.hpp"
#endif
#include <gmock/gmock.h>
#include <gtest/gtest.h>

namespace cucumber_cpp::library::cucumber_expression
{
    TEST(RegexStrategyFactory, ReturnsNonNullStrategy)
    {
        const auto strategy = CreateRegexStrategy(R"__((\d+))__");

        EXPECT_THAT(strategy, testing::NotNull());
    }

    TEST(RegexStrategyFactory, ReturnedStrategyCanMatch)
    {
        const auto strategy = CreateRegexStrategy(R"__((\d+))__");

        const auto result = strategy->Match("abc 42 def");

        ASSERT_THAT(result, testing::IsTrue());
        EXPECT_THAT(result->at(1)->value, testing::StrEq("42"));
    }

#ifdef CCR_HAS_RE2
    TEST(RegexStrategyFactory, ReturnsRe2StrategyForSupportedPattern)
    {
        const auto strategy = CreateRegexStrategy(R"__((\d+))__");

        EXPECT_THAT(dynamic_cast<Re2RegexStrategy*>(strategy.get()), testing::NotNull());
    }

    TEST(RegexStrategyFactory, FallsBackToStdStrategyForUnsupportedPattern)
    {
        // lookahead (?=) is not supported by RE2
        const auto strategy = CreateRegexStrategy(R"__((?=.*\d)\d+)__");

        EXPECT_THAT(dynamic_cast<StdRegexStrategy*>(strategy.get()), testing::NotNull());
    }
#else
    TEST(RegexStrategyFactory, ReturnsStdStrategy)
    {
        const auto strategy = CreateRegexStrategy(R"__((\d+))__");

        EXPECT_THAT(dynamic_cast<StdRegexStrategy*>(strategy.get()), testing::NotNull());
    }
#endif
}
