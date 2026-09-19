#include "cucumber/cucumber-expressions/Re2RegexStrategy.hpp"
#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include "cucumber/cucumber-expressions/Utils.hpp"
#include <cstddef>
#include <optional>
#include <re2/re2.h>
#include <re2/stringpiece.h>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber::cucumber_expressions
{
    Re2RegexStrategy::Re2RegexStrategy(std::string_view pattern)
        : pattern{ pattern }
        , re2{ this->pattern }
    {
        if (!re2.ok())
        {
            throw std::invalid_argument(re2.error());
        }
    }

    std::optional<Matches> Re2RegexStrategy::Match(std::string_view text) const
    {
        const int nCaptures = re2.NumberOfCapturingGroups();
        const int nSubmatch = nCaptures + 1;
        std::vector<re2::StringPiece> submatch(static_cast<std::size_t>(nSubmatch));

        if (!re2.Match(text, 0, static_cast<int>(text.size()), RE2::UNANCHORED, submatch.data(), nSubmatch))
        {
            return std::nullopt;
        }

        Matches result;
        result.reserve(static_cast<std::size_t>(nSubmatch));
        for (const auto& piece : submatch)
        {
            if (piece.data() == nullptr)
            {
                result.emplace_back(std::nullopt);
            }
            else
            {
                const auto startByte = static_cast<std::size_t>(piece.data() - text.data());
                const auto start = CodepointCount(text.substr(0, startByte));
                result.emplace_back(MatchGroup{
                    .value = std::string(piece),
                    .start = start,
                    .end = start + CodepointCount(std::string_view{ piece.data(), piece.size() }),
                });
            }
        }
        return result;
    }
}
