
#include "YamlTestData.hpp"
#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "cucumber/cucumber-expressions/RegularExpression.hpp"
#include "yaml-cpp/node/node.h"
#include "gmock/gmock.h"
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <optional>
#include <string>
#include <utility>
#include <vector>
#include <yaml-cpp/node/parse.h>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        struct TestRegularExpressionMatching : testing::TestWithParam<YamlTestCase>
        {
            ParameterRegistry parameterRegistry{ {} };
        };

        struct TestRegularExpression : testing::Test
        {
            ParameterRegistry parameterRegistry{ {} };

            template<class T>
            void MatchOnFirst(std::string expr, const std::string& text, const T& expected)
            {
                RegularExpression expression{ std::move(expr), parameterRegistry };

                const auto matches = expression.MatchToArguments(text);

                ASSERT_THAT(matches, testing::IsTrue());
                ASSERT_THAT(matches->size(), testing::Eq(1));
                EXPECT_THAT(matches->at(0).GetValue<T>(), testing::Eq(expected));
            }
        };
    }

    TEST_P(TestRegularExpressionMatching, MatchesExpectedArguments)
    {
        const auto& testdata = YAML::Load(GetParam().content);
        RegularExpression expression{ testdata["expression"].as<std::string>(), parameterRegistry };

        const auto matches = expression.MatchToArguments(testdata["text"].as<std::string>());
        ASSERT_THAT(matches, testing::IsTrue());

        const auto& expectedArgs = testdata["expected_args"];
        ASSERT_THAT(matches->size(), testing::Eq(expectedArgs.size()));

        for (std::size_t i = 0; i < expectedArgs.size(); ++i)
        {
            const auto actual = matches->at(i).GetValue<std::optional<std::string>>();

            if (expectedArgs[i].IsNull())
            {
                EXPECT_THAT(actual, testing::IsFalse());
            }
            else
            {
                EXPECT_THAT(actual, testing::Eq(expectedArgs[i].as<std::string>()));
            }
        }
    }

    INSTANTIATE_TEST_SUITE_P(FromTestData, TestRegularExpressionMatching,
        testing::ValuesIn(LoadYamlTestCases(std::filesystem::path{ TESTDATA_SRC } / "regular-expression" / "matching")), YamlTestCaseName);

    TEST_F(TestRegularExpression, DoesNotTransformByDefault)
    {
        MatchOnFirst<std::string>(R"__((\d\d))__", "22", "22");
    }

    TEST_F(TestRegularExpression, DoesNotTransformAnonymous)
    {
        MatchOnFirst<std::string>(R"__((.*))__", "22", "22");
    }

    TEST_F(TestRegularExpression, TransformsNegativeInt)
    {
        MatchOnFirst<int>(R"__((-?\d+))__", "-22", -22);
    }

    TEST_F(TestRegularExpression, TransformsPositiveInt)
    {
        MatchOnFirst<int>(R"__((\d+))__", "22", 22);
    }

    TEST_F(TestRegularExpression, ReturnsNulloptWhenDoesNotMatch)
    {
        RegularExpression expression{ R"__(hello)__", parameterRegistry };

        const auto matches = expression.MatchToArguments("world");

        ASSERT_THAT(matches, testing::IsFalse());
    }

    TEST_F(TestRegularExpression, MatchesEmptyString)
    {
        MatchOnFirst<std::string>(R"__(^The value equals "([^"]*)"$)__", R"__(The value equals "")__", "");
    }

    TEST_F(TestRegularExpression, MatchesNestedCaptureGroupWithoutMatch)
    {
        RegularExpression expression{ R"__(^a user( named "([^"]*)")?$)__", parameterRegistry };

        const auto matches = expression.MatchToArguments("a user");

        ASSERT_THAT(matches, testing::IsTrue());
        ASSERT_THAT(matches->size(), testing::Eq(1));
        EXPECT_THAT(matches->at(0).GetValue<std::optional<std::string>>(), testing::IsFalse());
    }

    TEST_F(TestRegularExpression, MatchesNestedCaptureGroupWithMatch)
    {
        MatchOnFirst<std::string>(R"__(^a user( named "([^"]*)")?$)__", R"__(a user named "Charlie")__", "Charlie");
    }

    TEST_F(TestRegularExpression, MatchesCaptureGroupNestedInOptionalOne)
    {
        RegularExpression expression{ R"__(^a (pre-commercial transaction |pre buyer fee model )?purchase(?: for \$(\d+))?$)__",
            parameterRegistry };

        const auto matches1 = expression.MatchToArguments("a purchase");
        ASSERT_THAT(matches1, testing::IsTrue());
        ASSERT_THAT(matches1->size(), testing::Eq(2));
        EXPECT_THAT(matches1->at(0).GetValue<std::optional<std::string>>(), testing::IsFalse());
        EXPECT_THAT(matches1->at(1).GetValue<std::optional<std::int32_t>>(), testing::IsFalse());

        const auto matches2 = expression.MatchToArguments("a purchase for $33");
        ASSERT_THAT(matches2, testing::IsTrue());
        ASSERT_THAT(matches2->size(), testing::Eq(2));
        EXPECT_THAT(matches2->at(0).GetValue<std::optional<std::string>>(), testing::IsFalse());
        EXPECT_THAT(matches2->at(1).GetValue<std::optional<std::int32_t>>(), testing::Eq(33));

        const auto matches3 = expression.MatchToArguments("a pre buyer fee model purchase");
        ASSERT_THAT(matches3, testing::IsTrue());
        ASSERT_THAT(matches3->size(), testing::Eq(2));
        EXPECT_THAT(matches3->at(0).GetValue<std::optional<std::string>>(), testing::Eq("pre buyer fee model "));
        EXPECT_THAT(matches3->at(1).GetValue<std::optional<std::int32_t>>(), testing::IsFalse());
    }

    TEST_F(TestRegularExpression, IgnoresNonCapturingGroups)
    {
        RegularExpression expression{
            R"__((\S+) ?(can|cannot)? (?:delete|cancel) the (\d+)(?:st|nd|rd|th) (attachment|slide) ?(?:upload)?)__", parameterRegistry
        };

        const auto matches = expression.MatchToArguments("I can cancel the 1st slide upload");
        ASSERT_THAT(matches, testing::IsTrue());
        ASSERT_THAT(matches->size(), testing::Eq(4));
        EXPECT_THAT(matches->at(0).GetValue<std::string>(), testing::Eq("I"));
        EXPECT_THAT(matches->at(1).GetValue<std::string>(), testing::Eq("can"));
        EXPECT_THAT(matches->at(2).GetValue<std::int32_t>(), testing::Eq(1));
        EXPECT_THAT(matches->at(3).GetValue<std::string>(), testing::Eq("slide"));
    }
}
