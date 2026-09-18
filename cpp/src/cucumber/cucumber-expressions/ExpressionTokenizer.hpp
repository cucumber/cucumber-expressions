#ifndef CUCUMBER_EXPRESSION_EXPRESSIONTOKENIZER_HPP
#define CUCUMBER_EXPRESSION_EXPRESSIONTOKENIZER_HPP

#include "cucumber/cucumber-expressions/Ast.hpp"
#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    struct ExpressionTokenizer
    {
        std::vector<Token> Tokenize(std::string_view expressionToTokenize);

    private:
        [[nodiscard]] TokenType TokenTypeOf(char ch, bool treatAsText) const;
        [[nodiscard]] static bool ShouldCreateNewToken(TokenType previousTokenType, TokenType currentTokenType);
        [[nodiscard]] Token CreateToken(TokenType type);

        std::string_view expression;

        std::size_t escapedCharacters{ 0 };
        std::string buffer;

        std::size_t startIndex{ 0 };
    };
}

#endif
