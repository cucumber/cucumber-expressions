#ifndef CUCUMBER_EXPRESSION_RE2REGEXSTRATEGY_HPP
#define CUCUMBER_EXPRESSION_RE2REGEXSTRATEGY_HPP

#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include "re2/re2.h"
#include <optional>
#include <string>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    struct Re2RegexStrategy : RegexStrategy
    {
        explicit Re2RegexStrategy(std::string_view pattern);

        [[nodiscard]] std::optional<Matches> Match(std::string_view text) const override;

    private:
        std::string pattern;
        re2::RE2 re2;
    };
}

#endif
