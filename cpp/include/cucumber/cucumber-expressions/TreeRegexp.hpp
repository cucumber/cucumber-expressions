#ifndef CUCUMBER_EXPRESSION_TREE_REGEXP_HPP
#define CUCUMBER_EXPRESSION_TREE_REGEXP_HPP

#include "cucumber/cucumber-expressions/Group.hpp"
#include "cucumber/cucumber-expressions/RegexStrategy.hpp"
#include <cstddef>
#include <list>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber::cucumber_expressions
{
    struct GroupBuilder
    {
        void Add(GroupBuilder groupBuilder);

        void SetNonCapturing();
        [[nodiscard]] bool IsCapturing() const;

        void SetPattern(std::string_view pattern);

        void MoveChildrenTo(GroupBuilder& target);

        [[nodiscard]] const std::list<GroupBuilder>& Children() const;
        [[nodiscard]] std::string_view Pattern() const;

        [[nodiscard]] ArgumentGroup Build(const std::vector<std::optional<MatchGroup>>& match, std::size_t& index) const;

    private:
        std::string_view pattern;
        bool capturing{ true };
        std::list<GroupBuilder> children;
    };

    struct TreeRegexp
    {
        explicit TreeRegexp(std::string_view pattern);
        ~TreeRegexp() = default;

        TreeRegexp(const TreeRegexp& other);
        TreeRegexp& operator=(const TreeRegexp& other);
        TreeRegexp(TreeRegexp&&) = default;
        TreeRegexp& operator=(TreeRegexp&&) = default;

        [[nodiscard]] const GroupBuilder& RootBuilder() const;
        [[nodiscard]] std::optional<ArgumentGroup> MatchToGroup(const std::string& text) const;

    private:
        std::string storedPattern;
        GroupBuilder rootGroupBuilder;
        std::unique_ptr<RegexStrategy> regexStrategy;
    };
}

#endif
