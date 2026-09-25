#include "cucumber/cucumber-expressions/Group.hpp"
#include <algorithm>
#include <iterator>
#include <optional>
#include <string>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        std::optional<std::string> ToString(const ArgumentGroup& group)
        {
            return group.value;
        }
    }

    std::vector<std::optional<std::string>> ArgumentGroup::Values() const
    {
        if (children.empty())
        {
            return { value };
        }

        std::vector<std::optional<std::string>> result;
        std::transform(children.begin(), children.end(), std::back_inserter(result), ToString);

        return result;
    }
}
