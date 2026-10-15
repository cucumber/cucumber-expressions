#ifndef CUCUMBER_EXPRESSION_REGEXSTRATEGYFACTORY_HPP
#define CUCUMBER_EXPRESSION_REGEXSTRATEGYFACTORY_HPP

#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include <memory>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    [[nodiscard]] std::unique_ptr<RegexStrategy> CreateRegexStrategy(std::string_view pattern);
}

#endif
