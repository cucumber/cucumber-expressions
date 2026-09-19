#include "YamlTestData.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/ExpressionParser.hpp"
#include "yaml-cpp/node/node.h"
#include <cstddef>
#include <filesystem>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <iostream>
#include <map>
#include <ostream>
#include <string>
#include <string_view>
#include <type_traits>
#include <variant>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        const std::map<std::string_view, NodeType> tokenTypeMap = {
            { "TEXT_NODE", NodeType::text },
            { "OPTIONAL_NODE", NodeType::optional },
            { "ALTERNATION_NODE", NodeType::alternation },
            { "ALTERNATIVE_NODE", NodeType::alternative },
            { "PARAMETER_NODE", NodeType::parameter },
            { "EXPRESSION_NODE", NodeType::expression },
        };

        Node CreateNode(const YAML::Node& yaml)
        {
            if (yaml["nodes"])
            {
                Node node{
                    tokenTypeMap.at(yaml["type"].as<std::string>()),
                    yaml["start"].as<std::size_t>(),
                    yaml["end"].as<std::size_t>(),
                    std::vector<Node>{},
                };

                for (const auto& child : yaml["nodes"])
                {
                    node.Children().push_back(CreateNode(child));
                }

                return node;
            }

            return {
                tokenTypeMap.at(yaml["type"].as<std::string>()),
                yaml["start"].as<std::size_t>(),
                yaml["end"].as<std::size_t>(),
                yaml["token"].as<std::string>(),
            };
        }

        Node CreateNodes(const YAML::Node& yaml)
        {
            return CreateNode(yaml);
        }
    }

    // Must live directly in this namespace (not a nested anonymous one) so gtest's ADL-based lookup finds it.
    void PrintTo(const Node& node, std::ostream* ostream)
    {
        std::visit(
            [&node, &ostream](const auto& arg)
            {
                if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, std::string>)
                {
                    *ostream << "{type:" << static_cast<std::size_t>(node.Type()) << " start:" << node.Start() << " end:" << node.End()
                             << " text: " << arg << "}";
                }
                else if constexpr (std::is_same_v<std::decay_t<decltype(arg)>, std::vector<Node>>)
                {
                    *ostream << "{type:" << static_cast<std::size_t>(node.Type()) << " start:" << node.Start() << " end:" << node.End()
                             << " children: [";
                    for (const auto& child : arg)
                    {
                        PrintTo(child, ostream);
                        *ostream << ", ";
                    }
                    *ostream << "]}";
                }
                else
                {
                    *ostream << "{type:" << static_cast<std::size_t>(node.Type()) << " start:" << node.Start() << " end:" << node.End()
                             << "}";
                }
            },
            node.GetLeafNodes());
    }

    namespace
    {
        struct TestExpressionParser : testing::TestWithParam<YamlTestCase>
        {};
    }

    TEST_P(TestExpressionParser, ParsesToExpectedAst)
    {
        const auto& testdata = GetParam().testdata;

        std::cout << "Running test: " << GetParam().name << std::endl;
        std::cout << "Test content: " << GetParam().content << std::endl;

        if (testdata["exception"])
        {
            ASSERT_ANY_THROW(ExpressionParser{}.Parse(testdata["expression"].as<std::string>()));
        }
        else
        {
            const auto actual = ExpressionParser{}.Parse(testdata["expression"].as<std::string>());
            const auto expected = CreateNode(testdata["expected_ast"]);
            ASSERT_THAT(actual, testing::Eq(expected));
        }
    }

    INSTANTIATE_TEST_SUITE_P(FromTestData, TestExpressionParser,
        testing::ValuesIn(LoadYamlTestCases(std::filesystem::path{ TESTDATA_SRC } / "cucumber-expression" / "parser")), YamlTestCaseName);
}
