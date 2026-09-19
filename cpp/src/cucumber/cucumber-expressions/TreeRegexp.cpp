#include "cucumber/cucumber-expressions/TreeRegexp.hpp"
#include "cucumber/cucumber-expressions/Group.hpp"
#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include "cucumber/cucumber-expressions/RegexStrategyFactory.hpp"
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <iterator>
#include <list>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        bool IsNonCapturing(std::string_view pattern, std::size_t pos)
        {
            if (pattern[pos + 1] != '?')
            {
                return false;
            }

            if (pattern[pos + 2] != '<')
            {
                return true;
            }

            return pattern[pos + 3] == '=' || pattern[pos + 3] == '!';
        }

        void StartGroup(std::deque<GroupBuilder>& stack, std::deque<std::size_t>& groupStartStack, std::string_view pattern,
            std::size_t patternIndex)
        {
            groupStartStack.emplace_back(patternIndex);
            auto& groupBuilder = stack.emplace_back();
            if (IsNonCapturing(pattern, patternIndex))
            {
                groupBuilder.SetNonCapturing();
            }
        }

        void FinalizeGroup(std::deque<GroupBuilder>& stack, std::deque<std::size_t>& groupStartStack, std::string_view pattern,
            std::size_t patternIndex)
        {
            if (stack.empty())
            {
                throw std::runtime_error("Empty stack");
            }

            auto groupBuilder = stack.back();
            stack.pop_back();

            auto groupStart = groupStartStack.empty() ? 0 : groupStartStack.back();
            groupStart += 1;

            if (!groupStartStack.empty())
            {
                groupStartStack.pop_back();
            }

            if (groupBuilder.IsCapturing())
            {
                groupBuilder.SetPattern(pattern.substr(groupStart, patternIndex - groupStart));
                stack.back().Add(groupBuilder);
            }
            else
            {
                groupBuilder.MoveChildrenTo(stack.back());
            }
        }

        struct PatternGroupParser
        {
            enum class State : std::uint8_t
            {
                nonGroup,
                groupStart,
                groupClose
            };

            State Parse(char chr)
            {
                State state{};

                if (chr == '[' && !escaping)
                {
                    charClass = true;
                }
                else if (chr == ']' && !escaping)
                {
                    charClass = false;
                }
                else if (chr == '(' && !escaping && !charClass)
                {
                    state = State::groupStart;
                }
                else if (chr == ')' && !escaping && !charClass)
                {
                    state = State::groupClose;
                }

                escaping = (chr == '\\' && !escaping);

                return state;
            }

        private:
            bool escaping{ false };
            bool charClass{ false };
        };

        GroupBuilder CreateGroupBuilder(std::string_view pattern)
        {
            std::deque<GroupBuilder> stack;
            std::deque<std::size_t> groupStartStack;
            PatternGroupParser patternParser;

            stack.emplace_back();

            for (std::size_t i = 0; i < pattern.size(); ++i)
            {
                const char chr = pattern[i];

                switch (patternParser.Parse(chr))
                {
                    case PatternGroupParser::State::groupStart:
                        StartGroup(stack, groupStartStack, pattern, i);
                        break;

                    case PatternGroupParser::State::groupClose:
                        FinalizeGroup(stack, groupStartStack, pattern, i);
                        break;

                    case PatternGroupParser::State::nonGroup:
                        break;
                }
            }

            if (stack.empty())
            {
                throw std::runtime_error("Empty stack");
            }

            return stack.back();
        }
    }

    void GroupBuilder::Add(GroupBuilder groupBuilder)
    {
        children.push_back(std::move(groupBuilder));
    }

    void GroupBuilder::SetNonCapturing()
    {
        capturing = false;
    }

    bool GroupBuilder::IsCapturing() const
    {
        return capturing;
    }

    void GroupBuilder::SetPattern(std::string_view pattern)
    {
        this->pattern = pattern;
    }

    void GroupBuilder::MoveChildrenTo(GroupBuilder& target)
    {
        for (auto& child : children)
        {
            target.Add(std::move(child));
        }

        children.clear();
    }

    const std::list<GroupBuilder>& GroupBuilder::Children() const
    {
        return children;
    }

    std::string_view GroupBuilder::Pattern() const
    {
        return pattern;
    }

    ArgumentGroup GroupBuilder::Build(const std::vector<std::optional<MatchGroup>>& match, std::size_t& index) const
    {
        const auto groupIndex = index++;
        const auto& matchGroupOpt = match[groupIndex];

        ArgumentGroup argumentGroup;
        argumentGroup.value = matchGroupOpt ? std::make_optional(matchGroupOpt->value) : std::nullopt;
        argumentGroup.start = matchGroupOpt ? std::make_optional(matchGroupOpt->start) : std::nullopt;
        argumentGroup.end = matchGroupOpt ? std::make_optional(matchGroupOpt->end) : std::nullopt;

        std::transform(children.begin(), children.end(), std::back_inserter(argumentGroup.children),
            [&match, &index](const auto& child)
            {
                return child.Build(match, index);
            });

        return argumentGroup;
    }

    TreeRegexp::TreeRegexp(std::string_view pattern)
        : storedPattern{ pattern }
        , rootGroupBuilder{ CreateGroupBuilder(storedPattern) }
        , regexStrategy{ CreateRegexStrategy(storedPattern) }
    {}

    TreeRegexp::TreeRegexp(const TreeRegexp& other)
        : storedPattern{ other.storedPattern }
        , rootGroupBuilder{ other.rootGroupBuilder }
        , regexStrategy{ CreateRegexStrategy(storedPattern) }
    {}

    TreeRegexp& TreeRegexp::operator=(const TreeRegexp& other)
    {
        if (this != &other)
        {
            storedPattern = other.storedPattern;
            rootGroupBuilder = other.rootGroupBuilder;
            regexStrategy = CreateRegexStrategy(storedPattern);
        }
        return *this;
    }

    const GroupBuilder& TreeRegexp::RootBuilder() const
    {
        return rootGroupBuilder;
    }

    std::optional<ArgumentGroup> TreeRegexp::MatchToGroup(const std::string& text) const
    {
        const auto matchResult = regexStrategy->Match(text);
        if (!matchResult)
        {
            return std::nullopt;
        }

        std::size_t index = 0;
        return rootGroupBuilder.Build(*matchResult, index);
    }
}
