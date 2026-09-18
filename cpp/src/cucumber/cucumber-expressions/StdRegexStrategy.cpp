#include "cucumber/cucumber-expressions/StdRegexStrategy.hpp"
#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include <cstddef>
#include <optional>
#include <regex>
#include <string>
#include <string_view>

namespace cucumber::cucumber_expressions
{
    StdRegexStrategy::StdRegexStrategy(std::string_view pattern)
        : regex{ std::string(pattern) }
    {}

    std::optional<Matches> StdRegexStrategy::Match(std::string_view text) const
    {
        std::smatch match;
        const std::string textStr(text);
        if (!std::regex_search(textStr, match, regex))
            return std::nullopt;

        Matches result;
        result.reserve(match.size());
        for (std::smatch::size_type i = 0; i < match.size(); ++i)
        {
            if (const auto& m = match[i]; !m.matched)
                result.emplace_back(std::nullopt);
            else
            {
                const auto start = static_cast<std::size_t>(match.position(i));
                result.emplace_back(MatchGroup{
                    .value = m.str(),
                    .start = start,
                    .end = start + static_cast<std::size_t>(m.length()),
                });
            }
        }
        return result;
    }
}
