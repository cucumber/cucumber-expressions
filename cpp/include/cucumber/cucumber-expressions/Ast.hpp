#ifndef CUCUMBER_EXPRESSION_AST_HPP
#define CUCUMBER_EXPRESSION_AST_HPP

#include <cstddef>
#include <cstdint>
#include <string>
#include <variant>
#include <vector>

namespace cucumber::cucumber_expressions
{
    enum class NodeType : std::uint8_t
    {
        text,
        optional,
        alternation,
        alternative,
        parameter,
        expression,
    };

    enum class TokenType : std::uint8_t
    {
        startOfLine,
        endOfLine,
        whiteSpace,
        beginOptional,
        endOptional,
        beginParameter,
        endParameter,
        alternation,
        text,
        invalid,
    };

    struct Node
    {
        Node(NodeType type, std::size_t start, std::size_t end, std::variant<std::string, std::vector<Node>> children);

        [[nodiscard]] NodeType Type() const;
        [[nodiscard]] std::size_t Start() const;
        [[nodiscard]] std::size_t End() const;

        [[nodiscard]] std::string Text();
        [[nodiscard]] std::string Text() const;

        [[nodiscard]] std::vector<Node>& Children();
        [[nodiscard]] const std::vector<Node>& Children() const;

        [[nodiscard]] const std::variant<std::string, std::vector<Node>>& GetLeafNodes() const;

        bool operator==(const Node& other) const;

    private:
        NodeType type;
        std::size_t start;
        std::size_t end;
        std::variant<std::string, std::vector<Node>> children;
    };

    struct Token
    {
        Token(TokenType type, std::string text, std::size_t start, std::size_t end);

        [[nodiscard]] TokenType Type() const;
        [[nodiscard]] std::string Text() const;
        [[nodiscard]] std::size_t Start() const;
        [[nodiscard]] std::size_t End() const;

        [[nodiscard]] static bool IsEscapeCharacter(char chr);
        [[nodiscard]] static TokenType TypeOf(char chr);
        [[nodiscard]] static bool CanEscape(char chr);
        [[nodiscard]] static std::string NameOf(TokenType type);
        [[nodiscard]] static std::string SymbolOf(TokenType type);
        [[nodiscard]] static std::string PurposeOf(TokenType type);

        bool operator==(const Token& other) const;

    private:
        TokenType type;
        std::string text;
        std::size_t start;
        std::size_t end;
    };
}

#endif
