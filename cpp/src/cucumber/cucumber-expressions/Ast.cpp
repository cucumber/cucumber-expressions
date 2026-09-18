#include "cucumber/cucumber-expressions/Ast.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include <cctype>
#include <cstddef>
#include <map>
#include <string>
#include <tuple>
#include <utility>
#include <variant>
#include <vector>

namespace cucumber_cpp::library::cucumber_expression
{
    namespace
    {
        const std::map<char, TokenType>& DemarcationMap()
        {
            static const std::map<char, TokenType> demarcationMap = {
                { '/', TokenType::alternation },
                { '{', TokenType::beginParameter },
                { '}', TokenType::endParameter },
                { '(', TokenType::beginOptional },
                { ')', TokenType::endOptional },
            };

            return demarcationMap;
        }
    }

    Node::Node(NodeType type, std::size_t start, std::size_t end, std::variant<std::string, std::vector<Node>> children)
        : type{ type }
        , start{ start }
        , end{ end }
        , children{ std::move(children) }
    {}

    NodeType Node::Type() const
    {
        return type;
    }

    std::size_t Node::Start() const
    {
        return start;
    }

    std::size_t Node::End() const
    {
        return end;
    }

    std::string Node::Text()
    {
        return static_cast<const Node*>(this)->Text();
    }

    std::string Node::Text() const
    {
        if (std::holds_alternative<std::string>(children))
        {
            return std::get<std::string>(children);
        }

        if (!std::get<std::vector<Node>>(children).empty())
        {
            std::string text;
            text.reserve(100);

            for (const auto& child : std::get<std::vector<Node>>(children))
            {
                text += child.Text();
            }
            return text;
        }

        return {};
    }

    std::vector<Node>& Node::Children()
    {
        return std::get<std::vector<Node>>(children);
    }

    const std::vector<Node>& Node::Children() const
    {
        return std::get<std::vector<Node>>(children);
    }

    const std::variant<std::string, std::vector<Node>>& Node::GetLeafNodes() const
    {
        return children;
    }

    bool Node::operator==(const Node& other) const
    {
        return std::make_tuple(type, start, end, children) == std::make_tuple(other.type, other.start, other.end, other.children);
    }

    Token::Token(TokenType type, std::string text, std::size_t start, std::size_t end)
        : type{ type }
        , text{ std::move(text) }
        , start{ start }
        , end{ end }
    {}

    TokenType Token::Type() const
    {
        return type;
    }

    std::string Token::Text() const
    {
        return text;
    }

    std::size_t Token::Start() const
    {
        return start;
    }

    std::size_t Token::End() const
    {
        return end;
    }

    bool Token::IsEscapeCharacter(char chr)
    {
        return chr == '\\';
    }

    TokenType Token::TypeOf(char chr)
    {
        if (std::isspace(static_cast<unsigned char>(chr)) != 0)
        {
            return TokenType::whiteSpace;
        }

        if (const auto iter = DemarcationMap().find(chr); iter != DemarcationMap().end())
        {
            return iter->second;
        }

        return TokenType::text;
    }

    bool Token::CanEscape(char chr)
    {
        if (std::isspace(static_cast<unsigned char>(chr)) != 0)
        {
            return true;
        }

        return chr == '\\' || DemarcationMap().find(chr) != DemarcationMap().end();
    }

    std::string Token::NameOf(TokenType type)
    {
        switch (type)
        {
            case TokenType::startOfLine:
                return "startOfLine";
            case TokenType::endOfLine:
                return "endOfLine";
            case TokenType::whiteSpace:
                return "whiteSpace";
            case TokenType::beginOptional:
                return "beginOptional";
            case TokenType::endOptional:
                return "endOptional";
            case TokenType::beginParameter:
                return "beginParameter";
            case TokenType::endParameter:
                return "endParameter";
            case TokenType::alternation:
                return "alternation";
            case TokenType::text:
                return "text";
            case TokenType::invalid:
                return "invalid";
        }

        throw InvalidTokenType{ "Invalid token type" };
    }

    std::string Token::SymbolOf(TokenType type)
    {
        for (const auto& [key, value] : DemarcationMap())
        {
            if (value == type)
            {
                return { key };
            }
        }

        return "";
    }

    std::string Token::PurposeOf(TokenType type)
    {
        if (type == TokenType::beginOptional || type == TokenType::endOptional)
        {
            return "optional text";
        }

        if (type == TokenType::beginParameter || type == TokenType::endParameter)
        {
            return "a parameter";
        }

        if (type == TokenType::alternation)
        {
            return "alternation";
        }
        return "";
    }

    bool Token::operator==(const Token& other) const
    {
        return std::make_tuple(type, text, start, end) == std::make_tuple(other.type, other.text, other.start, other.end);
    }
}
