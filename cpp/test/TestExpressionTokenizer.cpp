#include "YamlTestData.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/ExpressionTokenizer.hpp"
#include "yaml-cpp/node/node.h"
#include "gmock/gmock.h"
#include <cstddef>
#include <filesystem>
#include <gtest/gtest.h>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    namespace
    {
        const std::map<std::string_view, TokenType> tokenTypeMap = { { "START_OF_LINE", TokenType::startOfLine },
            { "END_OF_LINE", TokenType::endOfLine }, { "TEXT", TokenType::text }, { "WHITE_SPACE", TokenType::whiteSpace },
            { "BEGIN_PARAMETER", TokenType::beginParameter }, { "END_PARAMETER", TokenType::endParameter },
            { "BEGIN_OPTIONAL", TokenType::beginOptional }, { "END_OPTIONAL", TokenType::endOptional },
            { "ALTERNATION", TokenType::alternation } };

        std::vector<Token> CreateTokens(const YAML::Node& node)
        {
            std::vector<Token> tokens;
            tokens.reserve(node.size());
            for (const auto& expectedToken : node)
            {
                tokens.emplace_back(tokenTypeMap.at(expectedToken["type"].as<std::string>()), expectedToken["text"].as<std::string>(),
                    expectedToken["start"].as<std::size_t>(), expectedToken["end"].as<std::size_t>());
            }
            return tokens;
        }

        struct TestExpressionTokenizerFromFile : testing::TestWithParam<YamlTestCase>
        {};
    }

    TEST_P(TestExpressionTokenizerFromFile, MatchesExpectedTokens)
    {
        const auto& testdata = GetParam().testdata;

        if (testdata["exception"])
        {
            ASSERT_ANY_THROW(ExpressionTokenizer{}.Tokenize(testdata["expression"].as<std::string>()));
        }
        else
        {
            const auto actual = ExpressionTokenizer{}.Tokenize(testdata["expression"].as<std::string>());
            const auto expected = CreateTokens(testdata["expected_tokens"]);
            ASSERT_THAT(actual, testing::ElementsAreArray(expected));
        }
    }

    INSTANTIATE_TEST_SUITE_P(FromTestData, TestExpressionTokenizerFromFile,
        testing::ValuesIn(LoadYamlTestCases(std::filesystem::path{ TESTDATA_SRC } / "cucumber-expression" / "tokenizer")),
        YamlTestCaseName);

    TEST(TestExpressionTokenizer, TestNameOf)
    {
        EXPECT_THAT(Token::NameOf(TokenType::startOfLine), testing::StrEq("startOfLine"));
        EXPECT_THAT(Token::NameOf(TokenType::endOfLine), testing::StrEq("endOfLine"));
        EXPECT_THAT(Token::NameOf(TokenType::whiteSpace), testing::StrEq("whiteSpace"));
        EXPECT_THAT(Token::NameOf(TokenType::beginOptional), testing::StrEq("beginOptional"));
        EXPECT_THAT(Token::NameOf(TokenType::endOptional), testing::StrEq("endOptional"));
        EXPECT_THAT(Token::NameOf(TokenType::beginParameter), testing::StrEq("beginParameter"));
        EXPECT_THAT(Token::NameOf(TokenType::endParameter), testing::StrEq("endParameter"));
        EXPECT_THAT(Token::NameOf(TokenType::alternation), testing::StrEq("alternation"));
        EXPECT_THAT(Token::NameOf(TokenType::text), testing::StrEq("text"));
    }
}
