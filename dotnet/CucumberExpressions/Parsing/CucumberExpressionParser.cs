using System;
using System.Collections.Generic;
using System.Linq;
using CucumberExpressions.Ast;

namespace CucumberExpressions.Parsing;

public class CucumberExpressionParser
{
    /*
     * text := whitespace | ')' | '}' | .
     */
    private static readonly ICucumberExpressionInnerParser TextParser = new DelegateParser((expression, tokens, current) =>
    {
        Token token = tokens[current];
        switch (token.Type)
        {
            case TokenType.WHITE_SPACE:
            case TokenType.TEXT:
            case TokenType.END_PARAMETER:
            case TokenType.END_OPTIONAL:
                return new CucumberExpressionParserResult(1, new Node(NodeType.TEXT_NODE, token.Start, token.End, token.Text));
            case TokenType.ALTERNATION:
                throw CucumberExpressionException.CreateAlternationNotAllowedInOptional(expression, token);
            case TokenType.BEGIN_PARAMETER:
            case TokenType.START_OF_LINE:
            case TokenType.END_OF_LINE:
            case TokenType.BEGIN_OPTIONAL:
            default:
                // If configured correctly this will never happen
                return new CucumberExpressionParserResult(0);
        }
    });

    /*
     * name := whitespace | .
     */
    private static readonly ICucumberExpressionInnerParser NameParser = new DelegateParser((expression, tokens, current) =>
    {
        Token token = tokens[current];
        switch (token.Type)
        {
            case TokenType.WHITE_SPACE:
            case TokenType.TEXT:
                return new CucumberExpressionParserResult(1, new Node(NodeType.TEXT_NODE, token.Start, token.End, token.Text));
            case TokenType.BEGIN_OPTIONAL:
            case TokenType.END_OPTIONAL:
            case TokenType.BEGIN_PARAMETER:
            case TokenType.END_PARAMETER:
            case TokenType.ALTERNATION:
                throw CucumberExpressionException.CreateInvalidParameterTypeName(token, expression);
            case TokenType.START_OF_LINE:
            case TokenType.END_OF_LINE:
            default:
                // If configured correctly this will never happen
                return new CucumberExpressionParserResult(0);
        }
    });

    /*
     * parameter := '{' + name* + '}'
     */
    private static readonly ICucumberExpressionInnerParser ParameterParser = ParseBetween(
        NodeType.PARAMETER_NODE,
        TokenType.BEGIN_PARAMETER,
        TokenType.END_PARAMETER,
        new[] { NameParser }
    );

    /*
     * optional := '(' + option* + ')'
     * option := optional | parameter | text
     */
    private static readonly ICucumberExpressionInnerParser OptionalParser;

    /*
     * alternation := alternative* + ( '/' + alternative* )+
     */
    private static readonly ICucumberExpressionInnerParser AlternativeSeparator = new DelegateParser((_, tokens, current) =>
    {
        if (!LookingAt(tokens, current, TokenType.ALTERNATION))
        {
            return new CucumberExpressionParserResult(0);
        }
        Token token = tokens[current];
        return new CucumberExpressionParserResult(1, new Node(NodeType.ALTERNATIVE_NODE, token.Start, token.End, token.Text));
    });

    private static readonly List<ICucumberExpressionInnerParser> AlternativeParsers;

    /*
     * alternation := (?<=left-boundary) + alternative* + ( '/' + alternative* )+ + (?=right-boundary)
     * left-boundary := whitespace | } | ^
     * right-boundary := whitespace | { | $
     * alternative: = optional | parameter | text
     */
    private static readonly ICucumberExpressionInnerParser AlternationParser = new DelegateParser((expression, tokens, current) =>
    {
        int previous = current - 1;
        if (!LookingAtAny(tokens, previous, TokenType.START_OF_LINE, TokenType.WHITE_SPACE, TokenType.END_PARAMETER))
        {
            return new CucumberExpressionParserResult(0);
        }

        CucumberExpressionParserResult result = ParseTokensUntil(expression, AlternativeParsers, tokens, current, TokenType.WHITE_SPACE, TokenType.END_OF_LINE, TokenType.BEGIN_PARAMETER);
        int subCurrent = current + result.Consumed;
        if (result.Ast.All(astNode => astNode.Type != NodeType.ALTERNATIVE_NODE))
        {
            return new CucumberExpressionParserResult(0);
        }

        int start = tokens[current].Start;
        int end = tokens[subCurrent].Start;
        // Does not consume right hand boundary token
        return new CucumberExpressionParserResult(result.Consumed,
                    new Node(NodeType.ALTERNATION_NODE, start, end, SplitAlternatives(start, end, result.Ast)));
    });

    /*
     * cucumber-expression :=  ( alternation | optional | parameter | text )*
     */
    private static readonly ICucumberExpressionInnerParser CucumberExpressionMainParser = ParseBetween(
        NodeType.EXPRESSION_NODE,
        TokenType.START_OF_LINE,
        TokenType.END_OF_LINE,
        () => new[]
        {
            AlternationParser,
            OptionalParser,
            ParameterParser,
            TextParser
        }
    );

    static CucumberExpressionParser()
    {
        OptionalParser = ParseBetween(
            NodeType.OPTIONAL_NODE,
            TokenType.BEGIN_OPTIONAL,
            TokenType.END_OPTIONAL,
            () => new[] { OptionalParser, ParameterParser, TextParser }
        );
        AlternativeParsers = new()
        {
            AlternativeSeparator,
            OptionalParser,
            ParameterParser,
            TextParser
        };
    }

    public Node Parse(string expression)
    {
        CucumberExpressionTokenizer tokenizer = new CucumberExpressionTokenizer();
        var tokens = tokenizer.Tokenize(expression);
        CucumberExpressionParserResult result = CucumberExpressionMainParser.Parse(expression, tokens, 0);
        return result.Ast[0];
    }

    private interface ICucumberExpressionInnerParser
    {
        CucumberExpressionParserResult Parse(string expression, Token[] tokens, int current);
    }

    private class DelegateParser : ICucumberExpressionInnerParser
    {
        private readonly Func<string, Token[], int, CucumberExpressionParserResult> _parseFunc;

        public DelegateParser(Func<string, Token[], int, CucumberExpressionParserResult> parseFunc)
        {
            _parseFunc = parseFunc;
        }
        public CucumberExpressionParserResult Parse(string expression, Token[] tokens, int current)
        {
            return _parseFunc(expression, tokens, current);
        }
    }

    private static ICucumberExpressionInnerParser ParseBetween(
        NodeType type,
        TokenType beginToken,
        TokenType endToken,
        ICucumberExpressionInnerParser[] parsers)
    {
        if (parsers.Any(p => p == null))
            throw new ArgumentException("Null parser used!", nameof(parsers));

        return ParseBetween(type, beginToken, endToken, () => parsers);
    }

    private static ICucumberExpressionInnerParser ParseBetween(
            NodeType type,
            TokenType beginToken,
            TokenType endToken,
            Func<ICucumberExpressionInnerParser[]> parsersFunc)
    {
        return new DelegateParser((expression, tokens, current) =>
        {
            if (!LookingAt(tokens, current, beginToken))
            {
                return new CucumberExpressionParserResult(0);
            }
            int subCurrent = current + 1;
            CucumberExpressionParserResult result = ParseTokensUntil(expression, parsersFunc(), tokens, subCurrent, endToken, TokenType.END_OF_LINE);
            subCurrent += result.Consumed;

            // endToken not found
            if (!LookingAt(tokens, subCurrent, endToken))
            {
                throw CucumberExpressionException.CreateMissingEndToken(expression, beginToken, endToken, tokens[current]);
            }
            // consumes endToken
            int start = tokens[current].Start;
            int end = tokens[subCurrent].End;
            return new CucumberExpressionParserResult(subCurrent + 1 - current, new Node(type, start, end, result.Ast));
        });
    }

    private static CucumberExpressionParserResult ParseTokensUntil(
            string expression,
            IEnumerable<ICucumberExpressionInnerParser> parsers,
            Token[] tokens,
            int startAt,
            params TokenType[] endTokens)
    {
        int current = startAt;
        int size = tokens.Length;
        var ast = new List<Node>();
        var parsersArray = parsers.ToArray();
        while (current < size)
        {
            if (LookingAtAny(tokens, current, endTokens))
            {
                break;
            }

            CucumberExpressionParserResult result = ParseToken(expression, parsersArray, tokens, current);
            if (result.Consumed == 0)
            {
                // If configured correctly this will never happen
                // Keep to avoid infinite loops
                throw new InvalidOperationException("No eligible parsers for " + tokens);
            }
            current += result.Consumed;
            ast.AddRange(result.Ast);
        }
        return new CucumberExpressionParserResult(current - startAt, ast.ToArray());
    }

    private static CucumberExpressionParserResult ParseToken(string expression, IEnumerable<ICucumberExpressionInnerParser> parsers,
            Token[] tokens,
            int startAt)
    {
        foreach (var parser in parsers)
        {
            CucumberExpressionParserResult result = parser.Parse(expression, tokens, startAt);
            if (result.Consumed != 0)
            {
                return result;
            }
        }
        // If configured correctly this will never happen
        throw new InvalidOperationException("No eligible parsers for " + tokens);
    }

    private static bool LookingAtAny(Token[] tokens, int at, params TokenType[] tokenTypes)
    {
        foreach (var tokeType in tokenTypes)
        {
            if (LookingAt(tokens, at, tokeType))
            {
                return true;
            }
        }
        return false;
    }

    private static bool LookingAt(Token[] tokens, int at, TokenType token)
    {
        if (at < 0)
        {
            // If configured correctly this will never happen
            // Keep for completeness
            return token == TokenType.START_OF_LINE;
        }
        if (at >= tokens.Length)
        {
            return token == TokenType.END_OF_LINE;
        }
        return tokens[at].Type == token;
    }

    private static Node[] SplitAlternatives(int start, int end, IEnumerable<Node> alternation)
    {
        var separators = new List<Node>();
        var alternatives = new List<List<Node>>();
        var alternative = new List<Node>();
        foreach (var n in alternation)
        {
            if (NodeType.ALTERNATIVE_NODE.Equals(n.Type))
            {
                separators.Add(n);
                alternatives.Add(alternative);
                alternative = new List<Node>();
            }
            else
            {
                alternative.Add(n);
            }
        }
        alternatives.Add(alternative);

        return CreateAlternativeNodes(start, end, separators, alternatives);
    }

    private static Node[] CreateAlternativeNodes(int start, int end, List<Node> separators, List<List<Node>> alternatives)
    {
        var nodes = new List<Node>();
        for (int i = 0; i < alternatives.Count; i++)
        {
            var n = alternatives[i];
            if (i == 0)
            {
                Node rightSeparator = separators[i];
                nodes.Add(new Node(NodeType.ALTERNATIVE_NODE, start, rightSeparator.Start, n.ToArray()));
            }
            else if (i == alternatives.Count - 1)
            {
                Node leftSeparator = separators[i - 1];
                nodes.Add(new Node(NodeType.ALTERNATIVE_NODE, leftSeparator.End, end, n.ToArray()));
            }
            else
            {
                Node leftSeparator = separators[i - 1];
                Node rightSeparator = separators[i];
                nodes.Add(new Node(NodeType.ALTERNATIVE_NODE, leftSeparator.End, rightSeparator.Start, n.ToArray()));
            }
        }
        return nodes.ToArray();
    }

}