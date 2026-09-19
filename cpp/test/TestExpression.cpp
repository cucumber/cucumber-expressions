
#include "YamlTestData.hpp"
#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/Expression.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "yaml-cpp/node/node.h"
#include "gmock/gmock.h"
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fmt/core.h>
#include <functional>
#include <gtest/gtest.h>
#include <limits>
#include <map>
#include <optional>
#include <string>
#include <yaml-cpp/node/parse.h>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        std::string FormatTestFailureMessage(const std::string& file, const YAML::Node& node, const Expression& expression)
        {
            return fmt::format("file:           {}\n"
                               "failed to match {}\n"
                               "regex           {}\n"
                               "against         {}",
                file, node["expression"].as<std::string>(), expression.Pattern(), node["text"].as<std::string>());
        }

        using ArgumentChecker =
            std::function<void(const Argument&, const YAML::Node&, const std::string&, const YAML::Node&, const Expression&)>;

        template<class T>
        ArgumentChecker CheckArgumentAs()
        {
            return [](const Argument& argument, const YAML::Node& expected, const std::string& file, const YAML::Node& testdata,
                       const Expression& expression)
            {
                EXPECT_THAT(argument.GetValue<T>(), expected.as<T>()) << FormatTestFailureMessage(file, testdata, expression);
            };
        }

        const std::map<std::string, ArgumentChecker> argumentCheckersByName = {
            { "", CheckArgumentAs<std::string>() },
            { "int", CheckArgumentAs<std::int32_t>() },
            { "float", CheckArgumentAs<float>() },
            { "word", CheckArgumentAs<std::string>() },
            { "string", CheckArgumentAs<std::string>() },
            { "bigdecimal", CheckArgumentAs<double>() },
            { "biginteger", CheckArgumentAs<std::int64_t>() },
            { "byte", CheckArgumentAs<std::int8_t>() },
            { "short", CheckArgumentAs<std::int16_t>() },
            { "long", CheckArgumentAs<std::int64_t>() },
            { "double", CheckArgumentAs<double>() },
        };

        struct TestExpression : testing::Test
        {
            ParameterRegistry parameterRegistry{ {} };

            template<class T>
            std::optional<T> Match(const std::string& expr, const std::string& text)
            {
                Expression expression{ expr, parameterRegistry };
                const auto& args = expression.MatchToArguments(text);

                if (!args.has_value())
                {
                    return std::nullopt;
                }

                return args.value()[0].GetValue<T>();
            }
        };

        struct TestExpressionMatching : testing::TestWithParam<YamlTestCase>
        {
            ParameterRegistry parameterRegistry{ {} };
        };
    }

    TEST_P(TestExpressionMatching, MatchesExpectedArguments)
    {
        const auto& param = GetParam();
        const auto& testdata = YAML::Load(param.content);

        if (testdata["exception"] && !testdata["text"])
        {
        }
        else if (testdata["exception"])
        {
            const auto expr = testdata["expression"].as<std::string>();
            const auto text = testdata["text"].as<std::string>();
            ASSERT_ANY_THROW((void)Expression(expr, parameterRegistry).MatchToArguments(text))
                << fmt::format("Test failed for file: {}", param.name);
        }
        else
        {
            const auto expression = Expression{ testdata["expression"].as<std::string>(), parameterRegistry };

            if (testdata["expected_args"].IsNull())
            {
                ASSERT_THAT(expression.MatchToArguments(testdata["text"].as<std::string>()), testing::IsFalse())
                    << FormatTestFailureMessage(param.name, testdata, expression);
            }
            else
            {
                const auto matchOpt = expression.MatchToArguments(testdata["text"].as<std::string>());

                ASSERT_THAT(matchOpt, testing::IsTrue()) << FormatTestFailureMessage(param.name, testdata, expression);

                const auto& match = *matchOpt;
                for (std::size_t i = 0; i < testdata["expected_args"].size(); ++i)
                {
                    const auto& argument = match[i];

                    if (argument.Name() == "biginteger")
                    {
                        GTEST_SKIP() << "Can't parse biginteger";
                    }

                    const auto checkerIt = argumentCheckersByName.find(argument.Name());
                    if (checkerIt == argumentCheckersByName.end())
                    {
                        FAIL() << "Unknown type: " << argument.Name() << " for:\n"
                               << FormatTestFailureMessage(param.name, testdata, expression);
                        continue;
                    }

                    checkerIt->second(argument, testdata["expected_args"][i], param.name, testdata, expression);
                }
            }
        }
    }

    INSTANTIATE_TEST_SUITE_P(FromTestData, TestExpressionMatching,
        testing::ValuesIn(LoadYamlTestCases(std::filesystem::path{ TESTDATA_SRC } / "cucumber-expression" / "matching")), YamlTestCaseName);

    TEST_F(TestExpression, MatchFloat)
    {
        EXPECT_THAT(Match<float>(R"__({float})__", R"__()__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(.)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(,)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(E)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(,1)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1.)__"), testing::IsFalse());

        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1)__").value(), testing::FloatNear(1.0F, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-1)__").value(), testing::FloatNear(-1.0F, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1.1)__").value(), testing::FloatNear(1.1F, std::numeric_limits<float>::epsilon()));

        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,000)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,000,0)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,000.1)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,000,10)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,0.1)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,000,000.1)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-1.1)__").value(),
            testing::FloatNear(-1.1F, std::numeric_limits<float>::epsilon()));

        EXPECT_THAT(Match<float>(R"__({float})__", R"__(.1)__").value(), testing::FloatNear(0.1F, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1)__").value(), testing::FloatNear(-0.1F, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1000001)__").value(),
            testing::FloatNear(-0.1000001F, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1E1)__").value(), testing::FloatNear(10.0, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(.1E1)__").value(), testing::FloatNear(1, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(1,E1)__"), testing::IsFalse());
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.01)__").value(),
            testing::FloatNear(-0.01, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E-1)__").value(),
            testing::FloatNear(-0.01, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E-2)__").value(),
            testing::FloatNear(-0.001, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E+1)__").value(), testing::FloatNear(-1, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E+2)__").value(),
            testing::FloatNear(-10, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E1)__").value(), testing::FloatNear(-1, std::numeric_limits<float>::epsilon()));
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(-.1E2)__").value(), testing::FloatNear(-10, std::numeric_limits<float>::epsilon()));
    }

    TEST_F(TestExpression, FloatWithZero)
    {
        EXPECT_THAT(Match<float>(R"__({float})__", R"__(0)__").value(), testing::FloatNear(0.0F, std::numeric_limits<float>::epsilon()));
    }

    TEST_F(TestExpression, MatchAnonymous)
    {
        EXPECT_THAT(Match<std::string>(R"__({})__", R"__(0.22)__").value(), testing::StrEq("0.22"));
    }

    TEST_F(TestExpression, MatchCustom)
    {
        struct CustomType
        {
            std::optional<std::string> text;
            std::optional<std::int64_t> number;
        };

        parameterRegistry.AddParameter<std::optional<CustomType>>("textAndOrNumber", { R"(([A-Z]+)?(?: )?([0-9]+)?)" },
            [](const ConvertFunctionArg& matches) -> std::optional<CustomType>
            {
                std::optional<std::string> text{ matches[0] };
                std::optional<std::int64_t> number{ matches[1].has_value() ? StringTo<std::int64_t>(matches[1].value())
                                                                           : std::optional<std::int64_t>{ std::nullopt } };
                return CustomType{ text, number };
            });

        auto matchString{ Match<CustomType>(R"__({textAndOrNumber})__", R"__(ABC)__") };
        EXPECT_THAT(matchString, testing::IsTrue());
        EXPECT_THAT(matchString.value().text.value(), testing::StrEq("ABC"));
        EXPECT_THAT(matchString.value().number, testing::IsFalse());

        auto matchInt{ Match<CustomType>(R"__({textAndOrNumber})__", R"__(123)__") };
        EXPECT_THAT(matchInt, testing::IsTrue());
        EXPECT_THAT(matchInt.value().text, testing::IsFalse());
        EXPECT_THAT(matchInt.value().number.value(), testing::Eq(123));

        auto matchStringAndInt{ Match<CustomType>(R"__({textAndOrNumber})__", R"__(ABC 123)__") };
        EXPECT_THAT(matchStringAndInt, testing::IsTrue());
        EXPECT_THAT(matchStringAndInt.value().text.value(), testing::StrEq("ABC"));
        EXPECT_THAT(matchStringAndInt.value().number.value(), testing::Eq(123));
    }

    TEST_F(TestExpression, ExposeSource)
    {
        const auto* expr = "I have {int} cuke(s)";
        Expression expression{ expr, parameterRegistry };
        EXPECT_THAT(expr, testing::StrEq(expression.Source()));
    }

    TEST_F(TestExpression, MatchBoolean)
    {
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(true)__").value(), testing::IsTrue());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(1)__").value(), testing::IsTrue());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(yes)__").value(), testing::IsTrue());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(on)__").value(), testing::IsTrue());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(enabled)__").value(), testing::IsTrue());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(active)__").value(), testing::IsTrue());

        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(false)__").value(), testing::IsFalse());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(0)__").value(), testing::IsFalse());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(2)__").value(), testing::IsFalse());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(off)__").value(), testing::IsFalse());
        EXPECT_THAT(Match<bool>(R"__({bool})__", R"__(foo)__").value(), testing::IsFalse());
    }

    TEST_F(TestExpression, ThrowUnknownParameterType)
    {
        const auto* expr = "I have {doesnotexist} cuke(s)";

        try
        {
            Expression expression{ expr, parameterRegistry };
            FAIL() << "Expected UndefinedParameterTypeError to be thrown";
        }
        catch (const UndefinedParameterTypeError& e)
        {
            EXPECT_THAT(e.what(), testing::StrEq("This Cucumber Expression has a problem at column 8:\n"
                                                 "\n"
                                                 "I have {doesnotexist} cuke(s)\n"
                                                 "       ^------------^\n"
                                                 "Undefined parameter type 'doesnotexist'\n"
                                                 "Please register a ParameterType for 'doesnotexist'\n"));
        }
    }

    TEST_F(TestExpression, ThrowDuplicateAnonymousParameterError)
    {
        try
        {
            parameterRegistry.AddParameter<std::string>("", { ".*" },
                [](const ConvertFunctionArg& matches) -> std::string
                {
                    return matches[0].value();
                });
            FAIL() << "Expected CucumberExpressionError to be thrown";
        }
        catch (const CucumberExpressionError& e)
        {
            EXPECT_THAT(e.what(), testing::StrEq("The anonymous parameter type has already been defined"));
        }
    }

    TEST_F(TestExpression, ThrowDuplicateParameterError)
    {
        try
        {
            parameterRegistry.AddParameter<std::string>("word", { ".*" },
                [](const ConvertFunctionArg& matches) -> std::string
                {
                    return matches[0].value();
                });
            FAIL() << "Expected CucumberExpressionError to be thrown";
        }
        catch (const CucumberExpressionError& e)
        {
            EXPECT_THAT(e.what(), testing::StrEq("There is already a parameter with name word"));
        }
    }
}
