#ifndef CUCUMBER_EXPRESSION_REGEXSTRATEGYFACTORY_HPP
#define CUCUMBER_EXPRESSION_REGEXSTRATEGYFACTORY_HPP

#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include <memory>
#include <string_view>

namespace cucumber_cpp::library::cucumber_expression
{
    [[nodiscard]] std::unique_ptr<RegexStrategy> CreateRegexStrategy(std::string_view pattern);
}

#endif
