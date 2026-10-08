#ifndef CUCUMBER_EXPRESSION_STDREGEXSTRATEGY_HPP
#define CUCUMBER_EXPRESSION_STDREGEXSTRATEGY_HPP

#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include <optional>
#include <regex>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    struct StdRegexStrategy : RegexStrategy
    {
        explicit StdRegexStrategy(std::string_view pattern);

        [[nodiscard]] std::optional<Matches> Match(std::string_view text) const override;

    private:
        std::regex regex;
    };
}

#endif
