#ifndef CUCUMBER_EXPRESSION_EXPRESSION_HPP
#define CUCUMBER_EXPRESSION_EXPRESSION_HPP

#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "cucumber/cucumber-expressions/TreeRegexp.hpp"
#include <cctype>
#include <cstdlib>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    struct Expression
    {
        Expression(std::string expression, ParameterRegistry& parameterRegistry);

        [[nodiscard]] std::string_view Source() const;
        [[nodiscard]] std::string_view Pattern() const;

        [[nodiscard]] std::optional<std::vector<Argument>> MatchToArguments(const std::string& text) const;

    private:
        std::string RewriteToRegex(const Node& node);
        std::string RewriteOptional(const Node& node);
        std::string RewriteAlternation(const Node& node);
        std::string RewriteAlternative(const Node& node);
        std::string RewriteParameter(const Node& node);
        std::string RewriteExpression(const Node& node);

        std::string expression;
        ParameterRegistry& parameterRegistry;
        std::vector<ParameterType> parameters;
        std::string pattern;

        TreeRegexp treeRegexp;
    };
}

#endif
