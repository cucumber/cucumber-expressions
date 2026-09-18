#ifndef CUCUMBER_EXPRESSION_REGEXSTRATEGY_HPP
#define CUCUMBER_EXPRESSION_REGEXSTRATEGY_HPP

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    struct MatchGroup
    {
        std::string value;
        std::size_t start;
        std::size_t end;
    };

    using Matches = std::vector<std::optional<MatchGroup>>;

    struct RegexStrategy
    {
        RegexStrategy() = default;
        virtual ~RegexStrategy() = default;

        [[nodiscard]] virtual std::optional<Matches> Match(std::string_view text) const = 0;
    };
}

#endif
