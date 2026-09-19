#include "cucumber/cucumber-expressions/ExpressionParser.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/ExpressionTokenizer.hpp"
#include <algorithm>
#include <cstddef>
#include <functional>
#include <optional>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        struct MatchTokenHelper
        {
            TokenType t;

            template<class... TArgs>
            bool in(TArgs&&... args)
            {
                return (... || (std::forward<TArgs>(args) == t));
            }
        };

        auto MatchToken(TokenType expected)
        {
            return MatchTokenHelper{ expected };
        }

        bool LookingAt(const std::vector<Token>& tokens, std::size_t position, TokenType type)
        {
            if (position > tokens.size())
            {
                return type == TokenType::endOfLine;
            }

            return tokens[position].Type() == type;
        }

        bool LookingAtAny(const std::vector<Token>& tokens, std::size_t position, const std::vector<TokenType>& types)
        {

            return std::any_of(types.begin(), types.end(),
                [tokens, position](TokenType type)
                {
                    return LookingAt(tokens, position, type);
                });
        }

        std::vector<Node> CreateAlternativeNodes(std::size_t start, std::size_t end, const std::vector<Node>& separators,
            const std::vector<std::vector<Node>>& alternatives)
        {
            std::vector<Node> retval;

            for (std::size_t index = 0, max = alternatives.size(); index < max; ++index)
            {
                if (index == 0)
                {
                    const auto& rightSeparator = separators[index];
                    retval.emplace_back(NodeType::alternative, start, rightSeparator.Start(), alternatives[index]);
                }
                else if (index == max - 1)
                {
                    const auto& leftSeparator = separators[index - 1];
                    retval.emplace_back(NodeType::alternative, leftSeparator.End(), end, alternatives[index]);
                }
                else
                {
                    const auto& rightSeparator = separators[index];
                    const auto& leftSeparator = separators[index - 1];
                    retval.emplace_back(NodeType::alternative, leftSeparator.End(), rightSeparator.Start(), alternatives[index]);
                }
            }
            return retval;
        }

        std::vector<Node> SplitAlternatives(std::size_t start, std::size_t end, const std::vector<Node>& alternation)
        {
            std::vector<Node> separators;
            std::vector<std::vector<Node>> alternatives{ {} };

            for (const auto& node : alternation)
            {
                if (node.Type() == NodeType::alternative)
                {
                    separators.push_back(node);
                    alternatives.emplace_back();
                }
                else
                {
                    alternatives.back().push_back(node);
                }
            }

            return CreateAlternativeNodes(start, end, separators, alternatives);
        }
    }

    ExpressionParser::Result ExpressionParser::SubParser::Parse(const ParserState& parserState) const
    {
        return this->parser(parserState, *this);
    }

    Node ExpressionParser::Parse(std::string_view expression)
    {
        tokens = ExpressionTokenizer{}.Tokenize(expression);

        ExpressionParser::SubParser parseText = { [](const ParserState& parserState,
                                                      const ExpressionParser::SubParser& /* subParser */) -> ExpressionParser::Result
            {
                const auto& token = parserState.tokens[parserState.current];
                if (MatchToken(token.Type()).in(TokenType::whiteSpace, TokenType::text, TokenType::endParameter, TokenType::endOptional))
                {
                    return { 1, Node{
                                    NodeType::text,
                                    token.Start(),
                                    token.End(),
                                    token.Text(),
                                } };
                }

                if (token.Type() == TokenType::alternation)
                {
                    throw AlternationNotAllowedInOptional{ parserState.expression, token };
                }

                return { 0, std::nullopt };
            } };

        ExpressionParser::SubParser parseName = { [](const ParserState& parserState,
                                                      const ExpressionParser::SubParser& /* subParser */) -> ExpressionParser::Result
            {
                const auto& token = parserState.tokens[parserState.current];
                if (MatchToken(token.Type()).in(TokenType::whiteSpace, TokenType::text))
                {
                    return { 1, Node{
                                    NodeType::text,
                                    token.Start(),
                                    token.End(),
                                    token.Text(),
                                } };
                }

                if (MatchToken(token.Type())
                        .in(TokenType::beginParameter, TokenType::endParameter, TokenType::beginOptional, TokenType::endOptional,
                            TokenType::alternation))
                {
                    throw InvalidParameterTypeNameInNode{ parserState.expression, token };
                }

                return { 0, std::nullopt };
            } };

        auto parseParameter = ParseBetweenGenerator(NodeType::parameter, TokenType::beginParameter, TokenType::endParameter);
        parseParameter.subParsers = { parseName };

        auto parseOptional = ParseBetweenGenerator(NodeType::optional, TokenType::beginOptional, TokenType::endOptional);
        parseOptional.subParsers = { parseOptional, parseParameter, parseText };

        ExpressionParser::SubParser parseAlternativeSeparator = { [this](const ParserState& parserState,
                                                                      const SubParser& /* subParser */) -> Result
            {
                if (!LookingAt(tokens, parserState.current, TokenType::alternation))
                {
                    return { 0, std::nullopt };
                }

                auto token = tokens[parserState.current];
                return { 1, std::optional<Node>{
                                std::in_place_t{},
                                NodeType::alternative,
                                token.Start(),
                                token.End(),
                                token.Text(),
                            } };
            } };

        ExpressionParser::SubParser parseAlternation = { [this](const ParserState& parserState,
                                                             const SubParser& subParser) -> ExpressionParser::Result
            {
                auto previous = parserState.current - 1;
                if (!LookingAtAny(tokens, previous, { TokenType::startOfLine, TokenType::whiteSpace, TokenType::endParameter }))
                {
                    return { 0, std::nullopt };
                }

                auto [consumed, ast] = ParseTokensUntil(parserState.expression, subParser.subParsers, parserState.current,
                    { TokenType::whiteSpace, TokenType::endOfLine, TokenType::beginParameter });
                auto subCurrent = parserState.current + consumed;
                if (std::none_of(ast.begin(), ast.end(),
                        [](const auto& node)
                        {
                            return node.Type() == NodeType::alternative;
                        }))
                {
                    return { 0, std::nullopt };
                }

                auto start = tokens[parserState.current].Start();
                auto end = tokens[subCurrent].Start();

                return { consumed, Node{
                                       NodeType::alternation,
                                       start,
                                       end,
                                       SplitAlternatives(start, end, ast),
                                   } };
            },
            {
                parseAlternativeSeparator,
                parseOptional,
                parseParameter,
                parseText,
            } };

        auto parseCucumberExpression = ParseBetweenGenerator(NodeType::expression, TokenType::startOfLine, TokenType::endOfLine);
        parseCucumberExpression.subParsers = { parseAlternation, parseOptional, parseParameter, parseText };

        auto [opt, ast] = parseCucumberExpression.Parse(ParserState{ expression, tokens, 0 });
        return *ast;
    }

    ExpressionParser::SubParser ExpressionParser::ParseBetweenGenerator(NodeType type, TokenType beginToken, TokenType endToken) const
    {
        return { [this, type, beginToken, endToken](const ParserState& parserState, const SubParser& subParser) -> Result
            {
                if (!LookingAt(parserState.tokens, parserState.current, beginToken))
                {
                    return { 0, std::nullopt };
                }

                auto subCurrent = parserState.current + 1;
                auto [consumed, ast] =
                    ParseTokensUntil(parserState.expression, subParser.subParsers, subCurrent, { endToken, TokenType::endOfLine });
                subCurrent += consumed;

                // endToken not found
                if (!LookingAt(parserState.tokens, subCurrent, endToken))
                {
                    throw MissingEndToken{ parserState.expression, beginToken, endToken, parserState.tokens[parserState.current] };
                }

                // consumed endToken
                auto start = parserState.tokens[parserState.current].Start();
                auto end = parserState.tokens[subCurrent].End();
                consumed = subCurrent + 1 - parserState.current;
                return { consumed, Node{
                                       type,
                                       start,
                                       end,
                                       ast,
                                   } };
            } };
    }

    std::tuple<std::size_t, std::vector<Node>> ExpressionParser::ParseTokensUntil(std::string_view expression,
        const std::vector<std::reference_wrapper<SubParser>>& parsers, std::size_t startAt, const std::vector<TokenType>& endTokens) const
    {
        auto current = startAt;
        auto size = tokens.size();
        std::vector<Node> ast;

        while (current < size)
        {
            if (LookingAtAny(tokens, current, endTokens))
            {
                break;
            }

            auto [consumed, node] = ParseToken(expression, parsers, current);
            if (consumed == 0)
            {
                throw NoEligibleParsers{ tokens };
            }

            current += consumed;
            ast.emplace_back(*node);
        }
        return { current - startAt, ast };
    }

    ExpressionParser::Result ExpressionParser::ParseToken(std::string_view expression,
        const std::vector<std::reference_wrapper<SubParser>>& parsers, std::size_t startAt) const
    {
        for (const auto& parser : parsers)
        {
            auto [consumed, ast] = parser.get().Parse(ParserState{ expression, tokens, startAt });
            if (consumed > 0)
            {
                return { consumed, ast };
            }
        }

        throw NoEligibleParsers{ tokens };
    }
}
