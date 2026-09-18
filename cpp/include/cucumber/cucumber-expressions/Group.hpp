#ifndef CUCUMBER_EXPRESSION_GROUP_HPP
#define CUCUMBER_EXPRESSION_GROUP_HPP

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    struct ArgumentGroup
    {
        std::optional<std::string> value;
        std::optional<std::size_t> start;
        std::optional<std::size_t> end;

        std::vector<ArgumentGroup> children;

        [[nodiscard]] std::vector<std::optional<std::string>> Values() const;
    };
}

#endif
