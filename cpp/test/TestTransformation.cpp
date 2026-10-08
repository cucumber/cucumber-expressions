#include "YamlTestData.hpp"
#include "cucumber/cucumber-expressions/Expression.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "yaml-cpp/node/node.h"
#include "gmock/gmock.h"
#include <filesystem>
#include <gtest/gtest.h>
#include <string>
#include <yaml-cpp/node/parse.h>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        struct TestTransformation : testing::TestWithParam<YamlTestCase>
        {
            ParameterRegistry parameterRegistry{ {} };
        };
    }

    TEST_P(TestTransformation, ProducesExpectedRegex)
    {
        const auto& testdata = YAML::Load(GetParam().content);

        const auto expression = Expression{ testdata["expression"].as<std::string>(), parameterRegistry };
        const auto actualRegex = expression.Pattern();

        EXPECT_THAT(actualRegex, testing::StrEq(testdata["expected_regex"].as<std::string>()));
    }

    INSTANTIATE_TEST_SUITE_P(FromTestData, TestTransformation,
        testing::ValuesIn(LoadYamlTestCases(std::filesystem::path{ TESTDATA_SRC } / "cucumber-expression" / "transformation")),
        YamlTestCaseName);
}
