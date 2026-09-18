#ifndef CUCUMBER_EXPRESSION_MATCH_RANGE_HPP
#define CUCUMBER_EXPRESSION_MATCH_RANGE_HPP

// IWYU pragma: private, include "cucumber_cpp/Steps.hpp"
// IWYU pragma: friend cucumber_cpp/.*

#include <regex>
#include <utility>

namespace cucumber_cpp::library::cucumber_expression
{
    struct MatchRange : std::pair<std::smatch::const_iterator, std::smatch::const_iterator>
    {
        using std::pair<std::smatch::const_iterator, std::smatch::const_iterator>::pair;
        using diff_t = std::smatch::const_iterator::difference_type;

        [[nodiscard]] std::smatch::const_iterator
        begin() const;
        [[nodiscard]] std::smatch::const_iterator end() const;

        [[nodiscard]] const std::ssub_match& operator[](diff_t index) const;
    };
}

#endif
