#ifndef CUCUMBER_EXPRESSION_EXPRESSIONPARSER_HPP
#define CUCUMBER_EXPRESSION_EXPRESSIONPARSER_HPP

#include "cucumber/cucumber-expressions/Ast.hpp"
#include <cstddef>
#include <functional>
#include <optional>
#include <string_view>
#include <tuple>
#include <vector>

namespace cucumber::cucumber_expressions
{
    struct ExpressionParser
    {
        Node Parse(std::string_view expression);

        struct Result
        {
            std::size_t consumed{};
            std::optional<Node> node;
        };

        struct ParserState
        {
            std::string_view expression;
            std::vector<Token> tokens;
            std::size_t current;
        };

        struct SubParser
        {
            std::function<Result(const ParserState& parser, const SubParser& subParser)> parser;
            std::vector<std::reference_wrapper<SubParser>> subParsers;

            [[nodiscard]] Result Parse(const ParserState& parser) const;
        };

    private:
        using Parsers = std::vector<std::function<Result(ParserState)>>;
        using Tokens = std::vector<Token>;

        [[nodiscard]] SubParser ParseBetweenGenerator(NodeType type, TokenType beginToken, TokenType endToken) const;

        [[nodiscard]] std::tuple<std::size_t, std::vector<Node>> ParseTokensUntil(std::string_view expression,
            const std::vector<std::reference_wrapper<SubParser>>& parsers, std::size_t startAt,
            const std::vector<TokenType>& endTokens) const;
        [[nodiscard]] Result ParseToken(std::string_view expression, const std::vector<std::reference_wrapper<SubParser>>& parsers,
            std::size_t startAt) const;

        Tokens tokens;
    };
}

#endif
