using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions;

public class CucumberExpressionParser
{
    /*
     * text := whitespace | ')' | '}' | .
     */
    private static readonly Parser textParser = new DelegateParser((expression, tokens, current) =>
    {
        Ast.Token token = tokens[current];
        switch (token.type)
        {
            case Ast.Token.Type.WHITE_SPACE:
            case Ast.Token.Type.TEXT:
            case Ast.Token.Type.END_PARAMETER:
            case Ast.Token.Type.END_OPTIONAL:
                return new Result(1, new Ast.Node(Ast.Node.Type.TEXT_NODE, token.start, token.end, token.text));
            case Ast.Token.Type.ALTERNATION:
                throw CucumberExpressionException.createAlternationNotAllowedInOptional(expression, token);
            case Ast.Token.Type.BEGIN_PARAMETER:
            case Ast.Token.Type.START_OF_LINE:
            case Ast.Token.Type.END_OF_LINE:
            case Ast.Token.Type.BEGIN_OPTIONAL:
            default:
                // If configured correctly this will never happen
                return new Result(0);
        }
    });

    /*
     * name := whitespace | .
     */
    private static readonly Parser nameParser = new DelegateParser((expression, tokens, current) =>
    {
        Ast.Token token = tokens[current];
        switch (token.type)
        {
            case Ast.Token.Type.WHITE_SPACE:
            case Ast.Token.Type.TEXT:
                return new Result(1, new Ast.Node(Ast.Node.Type.TEXT_NODE, token.start, token.end, token.text));
            case Ast.Token.Type.BEGIN_OPTIONAL:
            case Ast.Token.Type.END_OPTIONAL:
            case Ast.Token.Type.BEGIN_PARAMETER:
            case Ast.Token.Type.END_PARAMETER:
            case Ast.Token.Type.ALTERNATION:
                throw CucumberExpressionException.createInvalidParameterTypeName(token, expression);
            case Ast.Token.Type.START_OF_LINE:
            case Ast.Token.Type.END_OF_LINE:
            default:
                // If configured correctly this will never happen
                return new Result(0);
        }
    });

    /*
     * parameter := '{' + name* + '}'
     */
    private static readonly Parser parameterParser = parseBetween(
        Ast.Node.Type.PARAMETER_NODE,
        Ast.Token.Type.BEGIN_PARAMETER,
        Ast.Token.Type.END_PARAMETER,
        new[] { nameParser }
    );

    /*
     * optional := '(' + option* + ')'
     * option := optional | parameter | text
     */
    private static readonly Parser optionalParser;

    /*
     * alternation := alternative* + ( '/' + alternative* )+
     */
    private static readonly Parser alternativeSeparator = new DelegateParser((expression, tokens, current) =>
    {
        if (!lookingAt(tokens, current, Ast.Token.Type.ALTERNATION))
        {
            return new Result(0);
        }
        Ast.Token token = tokens[current];
        return new Result(1, new Ast.Node(Ast.Node.Type.ALTERNATIVE_NODE, token.start, token.end, token.text));
    });

    private static readonly List<Parser> alternativeParsers;

    /*
     * alternation := (?<=left-boundary) + alternative* + ( '/' + alternative* )+ + (?=right-boundary)
     * left-boundary := whitespace | } | ^
     * right-boundary := whitespace | { | $
     * alternative: = optional | parameter | text
     */
    private static readonly Parser alternationParser = new DelegateParser((expression, tokens, current) =>
    {
        int previous = current - 1;
        if (!lookingAtAny(tokens, previous, Ast.Token.Type.START_OF_LINE, Ast.Token.Type.WHITE_SPACE, Ast.Token.Type.END_PARAMETER))
        {
            return new Result(0);
        }

        Result result = parseTokensUntil(expression, alternativeParsers, tokens, current, Ast.Token.Type.WHITE_SPACE, Ast.Token.Type.END_OF_LINE, Ast.Token.Type.BEGIN_PARAMETER);
        int subCurrent = current + result.consumed;
        if (result.ast.All(astNode => astNode.type != Ast.Node.Type.ALTERNATIVE_NODE))
        {
            return new Result(0);
        }

        int start = tokens[current].start;
        int end = tokens[subCurrent].start;
        // Does not consume right hand boundary token
        return new Result(result.consumed,
                    new Ast.Node(Ast.Node.Type.ALTERNATION_NODE, start, end, splitAlternatives(start, end, result.ast)));
    });

    /*
     * cucumber-expression :=  ( alternation | optional | parameter | text )*
     */
    private static readonly Parser cucumberExpressionParser = parseBetween(
        Ast.Node.Type.EXPRESSION_NODE,
        Ast.Token.Type.START_OF_LINE,
        Ast.Token.Type.END_OF_LINE,
        () => new[]
        {
            alternationParser,
            optionalParser,
            parameterParser,
            textParser
        }
    );

    static CucumberExpressionParser()
    {
        optionalParser = parseBetween(
            Ast.Node.Type.OPTIONAL_NODE,
            Ast.Token.Type.BEGIN_OPTIONAL,
            Ast.Token.Type.END_OPTIONAL,
            () => new[] { optionalParser, parameterParser, textParser }
        );
        alternativeParsers = new()
        {
            alternativeSeparator,
            optionalParser,
            parameterParser,
            textParser
        };
    }

    public Ast.Node parse(String expression)
    {
        CucumberExpressionTokenizer tokenizer = new CucumberExpressionTokenizer();
        var tokens = tokenizer.tokenize(expression);
        Result result = cucumberExpressionParser.parse(expression, tokens, 0);
        return result.ast[0];
    }

    public interface Parser
    {
        Result parse(String expression, Ast.Token[] tokens, int current);
    }

    public class DelegateParser : Parser
    {
        private readonly Func<string, Ast.Token[], int, Result> _parseFunc;

        public DelegateParser(Func<string, Ast.Token[], int, Result> parseFunc)
        {
            _parseFunc = parseFunc;
        }
        public Result parse(string expression, Ast.Token[] tokens, int current)
        {
            return _parseFunc(expression, tokens, current);
        }
    }

    public class Result
    {
        public int consumed;
        public List<Ast.Node> ast;

        public Result(int consumed, params Ast.Node[] ast) :
            this(consumed, ast.ToList())
        {
        }

        public Result(int consumed, List<Ast.Node> ast)
        {
            this.consumed = consumed;
            this.ast = ast;
        }
    }

    private static Parser parseBetween(
        Ast.Node.Type type,
        Ast.Token.Type beginToken,
        Ast.Token.Type endToken,
        Parser[] parsers)
    {
        if (parsers.Any(p => p == null))
            throw new ArgumentException("Null parser used!", nameof(parsers));

        return parseBetween(type, beginToken, endToken, () => parsers);
    }

    private static Parser parseBetween(
            Ast.Node.Type type,
            Ast.Token.Type beginToken,
            Ast.Token.Type endToken,
            Func<Parser[]> parsersFunc)
    {
        return new DelegateParser((expression, tokens, current) =>
        {
            if (!lookingAt(tokens, current, beginToken))
            {
                return new Result(0);
            }
            int subCurrent = current + 1;
            Result result = parseTokensUntil(expression, parsersFunc(), tokens, subCurrent, endToken, Ast.Token.Type.END_OF_LINE);
            subCurrent += result.consumed;

            // endToken not found
            if (!lookingAt(tokens, subCurrent, endToken))
            {
                throw CucumberExpressionException.createMissingEndToken(expression, beginToken, endToken, tokens[current]);
            }
            // consumes endToken
            int start = tokens[current].start;
            int end = tokens[subCurrent].end;
            return new Result(subCurrent + 1 - current, new Ast.Node(type, start, end, result.ast));
        });
    }

    private static Result parseTokensUntil(
            String expression,
            IEnumerable<Parser> parsers,
            Ast.Token[] tokens,
            int startAt,
            params Ast.Token.Type[] endTokens)
    {
        int current = startAt;
        int size = tokens.Length;
        var ast = new List<Ast.Node>();
        while (current < size)
        {
            if (lookingAtAny(tokens, current, endTokens))
            {
                break;
            }

            Result result = parseToken(expression, parsers, tokens, current);
            if (result.consumed == 0)
            {
                // If configured correctly this will never happen
                // Keep to avoid infinite loops
                throw new InvalidOperationException("No eligible parsers for " + tokens);
            }
            current += result.consumed;
            ast.AddRange(result.ast);
        }
        return new Result(current - startAt, ast);
    }

    private static Result parseToken(String expression, IEnumerable<Parser> parsers,
            Ast.Token[] tokens,
            int startAt)
    {
        foreach (var parser in parsers)
        {
            Result result = parser.parse(expression, tokens, startAt);
            if (result.consumed != 0)
            {
                return result;
            }
        }
        // If configured correctly this will never happen
        throw new InvalidOperationException("No eligible parsers for " + tokens);
    }

    private static bool lookingAtAny(Ast.Token[] tokens, int at, params Ast.Token.Type[] tokenTypes)
    {
        foreach (var tokeType in tokenTypes)
        {
            if (lookingAt(tokens, at, tokeType))
            {
                return true;
            }
        }
        return false;
    }

    private static bool lookingAt(Ast.Token[] tokens, int at, Ast.Token.Type token)
    {
        if (at < 0)
        {
            // If configured correctly this will never happen
            // Keep for completeness
            return token == Ast.Token.Type.START_OF_LINE;
        }
        if (at >= tokens.Length)
        {
            return token == Ast.Token.Type.END_OF_LINE;
        }
        return tokens[at].type == token;
    }

    private static List<Ast.Node> splitAlternatives(int start, int end, List<Ast.Node> alternation)
    {
        var separators = new List<Ast.Node>();
        var alternatives = new List<List<Ast.Node>>();
        var alternative = new List<Ast.Node>();
        foreach (var n in alternation)
        {
            if (Ast.Node.Type.ALTERNATIVE_NODE.Equals(n.type))
            {
                separators.Add(n);
                alternatives.Add(alternative);
                alternative = new List<Ast.Node>();
            }
            else
            {
                alternative.Add(n);
            }
        }
        alternatives.Add(alternative);

        return createAlternativeNodes(start, end, separators, alternatives);
    }

    private static List<Ast.Node> createAlternativeNodes(int start, int end, List<Ast.Node> separators, List<List<Ast.Node>> alternatives)
    {
        var nodes = new List<Ast.Node>();
        for (int i = 0; i < alternatives.Count; i++)
        {
            List<Ast.Node> n = alternatives[i];
            if (i == 0)
            {
                Ast.Node rightSeparator = separators[i];
                nodes.Add(new Ast.Node(Ast.Node.Type.ALTERNATIVE_NODE, start, rightSeparator.start, n));
            }
            else if (i == alternatives.Count - 1)
            {
                Ast.Node leftSeparator = separators[i - 1];
                nodes.Add(new Ast.Node(Ast.Node.Type.ALTERNATIVE_NODE, leftSeparator.end, end, n));
            }
            else
            {
                Ast.Node leftSeparator = separators[i - 1];
                Ast.Node rightSeparator = separators[i];
                nodes.Add(new Ast.Node(Ast.Node.Type.ALTERNATIVE_NODE, leftSeparator.end, rightSeparator.start, n));
            }
        }
        return nodes;
    }

}
