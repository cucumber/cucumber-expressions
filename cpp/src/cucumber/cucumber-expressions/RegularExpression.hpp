#ifndef CUCUMBER_EXPRESSION_REGULAREXPRESSION_HPP
#define CUCUMBER_EXPRESSION_REGULAREXPRESSION_HPP

#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "cucumber/cucumber-expressions/TreeRegexp.hpp"
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    struct RegularExpression
    {
        explicit RegularExpression(std::string expression, const ParameterRegistry& parameterRegistry);

        [[nodiscard]] std::string_view Source() const;
        [[nodiscard]] std::string_view Pattern() const;

        [[nodiscard]] std::optional<std::vector<Argument>> MatchToArguments(const std::string& text) const;

    private:
        std::string expression;

        TreeRegexp treeRegexp;
        std::vector<ParameterType> parameters;
    };
}

#endif
