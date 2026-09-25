#ifndef CUCUMBER_CUCUMBER_EXPRESSIONS_UTILS_HPP
#define CUCUMBER_CUCUMBER_EXPRESSIONS_UTILS_HPP

#include <cstddef>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    [[nodiscard]] std::size_t CodepointCount(std::string_view text);
}

#endif
