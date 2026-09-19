#include "cucumber/cucumber-expressions/StdRegexStrategy.hpp"
#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include "cucumber/cucumber-expressions/Utils.hpp"
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
        std::smatch matches;
        const std::string textStr(text);
        if (!std::regex_search(textStr, matches, regex))
        {
            return std::nullopt;
        }

        Matches result;
        result.reserve(matches.size());
        for (std::smatch::size_type i = 0; i < matches.size(); ++i)
        {
            if (const auto& match = matches[i]; !match.matched)
            {
                result.emplace_back(std::nullopt);
            }
            else
            {
                const auto startByte = static_cast<std::size_t>(matches.position(i));
                const auto start = CodepointCount(std::string_view{ textStr.data(), startByte });
                const auto value = match.str();
                result.emplace_back(MatchGroup{
                    .value = value,
                    .start = start,
                    .end = start + CodepointCount(value),
                });
            }
        }
        return result;
    }
}
