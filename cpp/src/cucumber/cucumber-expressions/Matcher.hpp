#ifndef CUCUMBER_EXPRESSION_MATCHER_HPP
#define CUCUMBER_EXPRESSION_MATCHER_HPP

#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/Expression.hpp"
#include "cucumber/cucumber-expressions/RegularExpression.hpp"
#include <optional>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    using Matcher = std::variant<Expression, RegularExpression>;

    struct SourceVisitor
    {
        std::string_view operator()(const auto& expression) const
        {
            return expression.Source();
        }
    };

    struct PatternVisitor
    {
        std::string_view operator()(const auto& expression) const
        {
            return expression.Pattern();
        }
    };

    struct MatchVisitor
    {
        std::optional<std::vector<Argument>> operator()(const auto& expression) const
        {
            return expression.MatchToArguments(text);
        }

        const std::string& text;
    };
}

#endif
