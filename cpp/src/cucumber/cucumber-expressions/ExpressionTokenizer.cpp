#include "cucumber/cucumber-expressions/ExpressionTokenizer.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/Utils.hpp"
#include <cstddef>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    std::vector<Token> ExpressionTokenizer::Tokenize(std::string_view expressionToTokenize)
    {
        expression = expressionToTokenize;

        std::vector<Token> tokens;
        auto previousTokenType = TokenType::startOfLine;
        auto treatAsText = false;

        if (expression.empty())
        {
            tokens.emplace_back(TokenType::startOfLine, "", 0, 0);
        }

        for (const auto chr : expression)
        {
            if (Token::IsEscapeCharacter(chr) && !treatAsText)
            {
                ++escapedCharacters;
                treatAsText = true;
                continue;
            }

            auto currentTokenType = TokenTypeOf(chr, treatAsText);
            treatAsText = false;

            if (ShouldCreateNewToken(previousTokenType, currentTokenType))
            {
                tokens.push_back(CreateToken(previousTokenType));
            }

            previousTokenType = currentTokenType;
            buffer += chr;
        }

        if (!buffer.empty())
        {
            tokens.push_back(CreateToken(previousTokenType));
        }

        if (treatAsText)
        {
            throw TheEndOfLineCannotBeEscaped(expression);
        }

        tokens.emplace_back(TokenType::endOfLine, "", startIndex, startIndex);

        return tokens;
    }

    [[nodiscard]] TokenType ExpressionTokenizer::TokenTypeOf(char chr, bool treatAsText) const
    {
        if (!treatAsText)
        {
            return Token::TypeOf(chr);
        }

        if (Token::CanEscape(chr))
        {
            return TokenType::text;
        }

        throw CantEscape(expression, startIndex + CodepointCount(buffer) + escapedCharacters);
    }

    [[nodiscard]] bool ExpressionTokenizer::ShouldCreateNewToken(TokenType previousTokenType, TokenType currentTokenType)
    {
        return previousTokenType != currentTokenType || (currentTokenType != TokenType::whiteSpace && currentTokenType != TokenType::text);
    }

    [[nodiscard]] Token ExpressionTokenizer::CreateToken(TokenType type)
    {
        std::size_t escapedCount = 0;

        if (type == TokenType::text)
        {
            escapedCount = std::exchange(this->escapedCharacters, 0);
        }

        auto start = startIndex;
        auto end = startIndex + CodepointCount(buffer) + escapedCount;
        auto text = std::string{};
        std::swap(text, buffer);
        startIndex = end;

        return { type, text, start, end };
    }
}
