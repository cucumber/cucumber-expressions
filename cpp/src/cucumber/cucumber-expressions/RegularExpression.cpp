#include "cucumber/cucumber-expressions/RegularExpression.hpp"
#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "cucumber/cucumber-expressions/SourceLocation.hpp"
#include "cucumber/cucumber-expressions/TreeRegexp.hpp"
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    RegularExpression::RegularExpression(std::string expression, const ParameterRegistry& parameterRegistry)
        : expression{ std::move(expression) }
        , treeRegexp{ this->expression }
    {
        for (const auto& groupBuilder : treeRegexp.RootBuilder().Children())
        {
            const auto* parameterByRegexp = parameterRegistry.LookupByRegexp(std::string{ groupBuilder.Pattern() });
            if (parameterByRegexp != nullptr)
            {
                parameters.emplace_back(*parameterByRegexp);
            }
            else
            {

                parameters.push_back(ParameterType{ std::string{ "" }, std::vector<std::string>{ std::string{ groupBuilder.Pattern() } },
                    false, false, false, SourceLocation::current() });
            }
        }
    }

    std::string_view RegularExpression::Source() const
    {
        return expression;
    }

    std::string_view RegularExpression::Pattern() const
    {
        return expression;
    }

    std::optional<std::vector<Argument>> RegularExpression::MatchToArguments(const std::string& text) const
    {
        auto group = treeRegexp.MatchToGroup(text);
        if (!group.has_value())
        {
            return std::nullopt;
        }

        return Argument::BuildArguments(group.value(), parameters);
    }
}
