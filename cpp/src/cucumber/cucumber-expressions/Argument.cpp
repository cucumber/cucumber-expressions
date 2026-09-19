#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/Group.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "fmt/format.h"
#include <algorithm>
#include <cstddef>
#include <fmt/core.h>
#include <iterator>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    Argument::Argument(ArgumentGroup group, const ParameterType& parameter)
        : group{ std::move(group) }
        , parameter{ &parameter }
    {}

    std::vector<Argument> Argument::BuildArguments(const ArgumentGroup& group, const std::vector<ParameterType>& parameters)
    {
        if (group.children.size() != parameters.size())
        {
            throw std::runtime_error(
                fmt::format("Mismatch between number of groups ({}) and parameters ({})", group.children.size(), parameters.size()));
        }

        std::size_t index{ 0 };

        std::vector<Argument> arguments;
        arguments.reserve(parameters.size());

        auto converted = std::transform(parameters.begin(), parameters.end(), std::back_inserter(arguments),
            [&group, &index](const ParameterType& parameter) -> Argument
            {
                return { group.children[index++], parameter };
            });

        return arguments;
    }

    ArgumentGroup Argument::Group() const
    {
        return group;
    }

    std::string Argument::Name() const
    {
        return parameter->name;
    }

}
