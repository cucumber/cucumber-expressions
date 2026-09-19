#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include <cstddef>
#include <numeric>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        std::string PointAt(std::size_t column)
        {
            return std::string(column, ' ') + "^";
        }

        template<class T>
        std::string PointAtLocated(const T& node)
        {
            auto pointer = PointAt(node.Start());
            if (node.Start() + 1 < node.End())
            {
                pointer.resize(node.End() - 1, '-');
                pointer += "^";
            }
            return pointer;
        }
    }

    Error::Error(std::size_t column, std::string_view expression, std::string_view pointer, std::string_view problem,
        std::string_view solution)
        : std::runtime_error{ "This Cucumber Expression has a problem at column " + std::to_string(column + 1) + ":\n\n" +
                              std::string(expression) + "\n" + std::string(pointer) + "\n" + std::string(problem) + "\n" +
                              std::string(solution) + "\n" }
    {}

    CantEscape::CantEscape(std::string_view expression, std::size_t column)
        : Error{ column, expression, PointAt(column), R"(Only the characters '{', '}', '(', ')', '\', '/' and whitespace can be escaped)",
            R"(If you did mean to use an '\' you can use '\\' to escape it)" }
    {}

    TheEndOfLineCannotBeEscaped::TheEndOfLineCannotBeEscaped(std::string_view expression)
        : Error{ expression.length(), expression, PointAt(expression.length()), R"(The end of line can not be escaped)",
            R"(You can use '\\' to escape the '\')" }
    {}

    AlternationNotAllowedInOptional::AlternationNotAllowedInOptional(std::string_view expression, const Token& token)
        : Error{
            token.Start(),
            expression,
            PointAtLocated(token),
            R"(An alternation can not be used inside an optional)",
            R"(If you did not mean to use an alternation you can use '\/' to escape the '/'.
Otherwise rephrase your expression or consider using a regular expression instead.)",
        }
    {}

    InvalidParameterTypeNameInNode::InvalidParameterTypeNameInNode(std::string_view expression, const Token& token)
        : Error{
            token.Start(),
            expression,
            PointAtLocated(token),
            R"(Parameter names may not contain '{', '}', '(', ')', '\' or '/')",
            R"(Did you mean to use a regular expression?)",
        }
    {}

    MissingEndToken::MissingEndToken(std::string_view expression, TokenType beginToken, TokenType endToken, const Token& token)
        : Error{
            token.Start(),
            expression,
            PointAtLocated(token),
            std::string("The '") + Token::SymbolOf(beginToken) + "' does not have a matching '" + Token::SymbolOf(endToken) + "'",
            std::string("If you did not intend to use ") + Token::PurposeOf(beginToken) + " you can use '\\\\" +
                Token::SymbolOf(beginToken) + "' to escape the " + Token::PurposeOf(beginToken),
        }
    {}

    NoEligibleParsers::NoEligibleParsers(const std::vector<Token>& tokens)
        : std::runtime_error{
            "No eligible parsers for [" +
                std::accumulate(tokens.begin() + 1, tokens.end(), Token::NameOf(tokens.begin()->Type()),
                    [](const auto& acc, const auto& token) -> std::string
                    {
                        return acc + ", " + Token::NameOf(token.Type());
                    }) +
                "]",
        }
    {}

    OptionalMayNotBeEmpty::OptionalMayNotBeEmpty(const Node& node, std::string_view expression)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "An optional must contain some text",
            R"(If you did not mean to use an optional you can use '\(' to escape the '(')",
        }
    {}

    ParameterIsNotAllowedInOptional::ParameterIsNotAllowedInOptional(const Node& node, std::string_view expression)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "An optional may not contain a parameter type",
            R"(If you did not mean to use an parameter type you can use '\{' to escape the '{')",
        }
    {}

    OptionalIsNotAllowedInOptional::OptionalIsNotAllowedInOptional(const Node& node, std::string_view expression)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "An optional may not contain an other optional",
            R"(If you did not mean to use an optional type you can use '\(' to escape the '('.
For more complicated expressions consider using a regular expression instead.)",
        }
    {}

    AlternativeMayNotExclusivelyContainOptionals::AlternativeMayNotExclusivelyContainOptionals(const Node& node,
        std::string_view expression)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "An alternative may not exclusively contain optionals",
            R"(If you did not mean to use an optional you can use '\(' to escape the '(')",
        }
    {}

    AlternativeMayNotBeEmpty::AlternativeMayNotBeEmpty(const Node& node, std::string_view expression)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "Alternative may not be empty",
            R"(If you did not mean to use an alternative you can use '\/' to escape the '/')",
        }
    {}

    UndefinedParameterTypeError::UndefinedParameterTypeError(const Node& node, std::string expression, std::string undefinedParameterName)
        : Error{
            node.Start(),
            expression,
            PointAtLocated(node),
            "Undefined parameter type '" + undefinedParameterName + "'",
            "Please register a ParameterType for '" + undefinedParameterName + "'",
        }
        , expression{ std::move(expression) }
        , undefinedParameterName{ std::move(undefinedParameterName) }
    {}
}
