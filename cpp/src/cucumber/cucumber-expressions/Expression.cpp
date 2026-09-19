#include "cucumber/cucumber-expressions/Expression.hpp"
#include "cucumber/cucumber-expressions/Argument.hpp"
#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/ExpressionParser.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "fmt/format.h"
#include <algorithm>
#include <fmt/core.h>
#include <iterator>
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
        std::string EscapeRegex(std::string_view text)
        {
            using namespace std::literals;
            std::string escapedText{};
            escapedText.reserve(text.size() * 2);
            const auto escapePattern = R"(\^[({$.|?*+})])"sv;

            for (const auto& character : text)
            {
                if (std::find(escapePattern.begin(), escapePattern.end(), character) != escapePattern.end())
                {
                    escapedText += '\\';
                }
                escapedText += character;
            }

            return escapedText;
        }

        std::string CreateEmptyRegexString(const Node& node)
        {
            std::string partialRegex{};
            partialRegex.reserve(node.Children().size() * 10);
            return partialRegex;
        }

        bool NodesAreEmpty(const Node& node)
        {
            const auto& children = node.Children();
            return std::none_of(children.begin(), children.end(),
                [](const Node& child)
                {
                    return child.Type() == NodeType::text;
                });
        }

        bool ContainsNodeWithType(const Node& node, NodeType type)
        {
            const auto& children = node.Children();
            return std::any_of(children.begin(), children.end(),
                [type](const Node& child)
                {
                    return child.Type() == type;
                });
        }

        bool ContainsNodeWithParameters(const Node& node)
        {
            return ContainsNodeWithType(node, NodeType::parameter);
        }

        bool ContainsNodeWithOptionals(const Node& node)
        {
            return ContainsNodeWithType(node, NodeType::optional);
        }
    }

    Expression::Expression(std::string expression, ParameterRegistry& parameterRegistry)
        : expression{ std::move(expression) }
        , parameterRegistry{ parameterRegistry }
        , pattern{ RewriteToRegex(ExpressionParser{}.Parse(this->expression)) }
        , treeRegexp{ pattern }
    {}

    std::string_view Expression::Source() const
    {
        return expression;
    }

    std::string_view Expression::Pattern() const
    {
        return pattern;
    }

    std::optional<std::vector<Argument>> Expression::MatchToArguments(const std::string& text) const
    {
        auto group = treeRegexp.MatchToGroup(text);
        if (!group.has_value())
        {
            return std::nullopt;
        }

        return Argument::BuildArguments(group.value(), parameters);
    }

    std::string Expression::RewriteToRegex(const Node& node)
    {
        switch (node.Type())
        {
            case NodeType::text:
                return EscapeRegex(node.Text());
            case NodeType::optional:
                return RewriteOptional(node);
            case NodeType::alternation:
                return RewriteAlternation(node);
            case NodeType::alternative:
                return RewriteAlternative(node);
            case NodeType::parameter:
                return RewriteParameter(node);
            case NodeType::expression:
                return RewriteExpression(node);
        }

        throw InvalidNodeType{ "Invalid node type" };
    }

    std::string Expression::RewriteOptional(const Node& node)
    {
        std::string partialRegex{ CreateEmptyRegexString(node) };

        if (ContainsNodeWithParameters(node))
        {
            throw ParameterIsNotAllowedInOptional(node, expression);
        }

        if (ContainsNodeWithOptionals(node))
        {
            throw OptionalIsNotAllowedInOptional(node, expression);
        }

        if (NodesAreEmpty(node))
        {
            throw OptionalMayNotBeEmpty(node, expression);
        }

        for (const auto& child : node.Children())
        {
            partialRegex += RewriteToRegex(child);
        }

        return fmt::format(R"((?:{})?)", partialRegex);
    }

    std::string Expression::RewriteAlternation(const Node& node)
    {
        for (const auto& child : node.Children())
        {
            if (child.Children().empty())
            {
                throw AlternativeMayNotBeEmpty(node, expression);
            }

            if (NodesAreEmpty(child))
            {
                throw AlternativeMayNotExclusivelyContainOptionals(node, expression);
            }
        }

        std::string partialRegex{ CreateEmptyRegexString(node) };
        partialRegex += RewriteToRegex(node.Children().front());
        for (auto child = std::next(node.Children().begin()); child != node.Children().end(); ++child)
        {
            partialRegex += '|' + RewriteToRegex(*child);
        }

        return fmt::format(R"((?:{}))", partialRegex);
    }

    std::string Expression::RewriteAlternative(const Node& node)
    {
        std::string partialRegex{ CreateEmptyRegexString(node) };

        for (const auto& child : node.Children())
        {
            partialRegex += RewriteToRegex(child);
        }

        return partialRegex;
    }

    std::string Expression::RewriteParameter(const Node& node)
    {
        try
        {
            auto parameter = parameterRegistry.Lookup(node.Text());
            if (parameter.regex.empty())
            {
                throw UndefinedParameterTypeError(node, expression, node.Text());
            }

            parameters.push_back(parameter);

            std::string partialRegex{};
            if (parameter.regex.size() == 1)
            {
                partialRegex = fmt::format(R"(({}))", parameter.regex.front());
            }
            else
            {
                partialRegex = { parameter.regex.front() };
                for (auto parameterRegex = std::next(parameter.regex.begin()); parameterRegex != parameter.regex.end(); ++parameterRegex)
                {
                    partialRegex += R"()|(?:)" + *parameterRegex;
                }
                partialRegex = fmt::format(R"(((?:{})))", partialRegex);
            }
            return partialRegex;
        }
        catch (const std::out_of_range&)
        {
            throw UndefinedParameterTypeError(node, expression, node.Text());
        }
    }

    std::string Expression::RewriteExpression(const Node& node)
    {
        std::string partialRegex{ CreateEmptyRegexString(node) };

        for (const auto& child : node.Children())
        {
            partialRegex += RewriteToRegex(child);
        }

        return fmt::format("^{}$", partialRegex);
    }
}
