package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.util.List;
import java.util.Objects;
import java.util.StringJoiner;

import static java.util.Objects.requireNonNull;
import static java.util.stream.Collectors.joining;
import static org.apiguardian.api.API.Status.EXPERIMENTAL;

@API(since = "18.1", status = EXPERIMENTAL)
public final class Ast {

    public static final char escapeCharacter = '\\';
    public static final char alternationCharacter = '/';
    public static final char beginParameterCharacter = '{';
    public static final char endParameterCharacter = '}';
    public static final char beginOptionalCharacter = '(';
    public static final char endOptionalCharacter = ')';

    interface Located {
        int start();

        int end();

    }

    public static final class Node implements Located {

        private final NodeType type;
        private final List<Node> nodes;
        private final String token;
        private final int start;
        private final int end;

        Node(NodeType type, int start, int end, String token) {
            this(type, start, end, null, requireNonNull(token));
        }

        Node(NodeType type, int start, int end, List<Node> nodes) {
            this(type, start, end, requireNonNull(nodes), null);
        }

        private Node(NodeType type, int start, int end, List<Node> nodes, String token) {
            this.type = requireNonNull(type);
            this.nodes = nodes;
            this.token = token;
            this.start = start;
            this.end = end;
        }

        public enum NodeType {
            TEXT_NODE,
            OPTIONAL_NODE,
            ALTERNATION_NODE,
            ALTERNATIVE_NODE,
            PARAMETER_NODE,
            EXPRESSION_NODE
        }

        public int start() {
            return start;
        }

        public int end() {
            return end;
        }

        /**
         * @return child nodes, {@code null} if a leaf-node
         */
        public List<Node> nodes() {
            return nodes;
        }

        public NodeType type() {
            return type;
        }

        /**
         * @return the text contained with in this node, {@code null} if not a leaf-node
         */
        public String token() {
            return token;
        }

        String text() {
            if (nodes == null)
                return token;

            return nodes().stream()
                    .map(Node::text)
                    .collect(joining());
        }

        @Override
        public String toString() {
            return toString(0).toString();
        }

        private StringBuilder toString(int depth) {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < depth; i++) {
                sb.append("  ");
            }
            sb.append("{")
                    .append("\"type\": \"").append(type)
                    .append("\", \"start\": ")
                    .append(start)
                    .append(", \"end\": ")
                    .append(end);

            if (token != null) {
                sb.append(", \"token\": \"").append(token.replaceAll("\\\\", "\\\\\\\\")).append("\"");
            }

            if (nodes != null) {
                sb.append(", \"nodes\": ");
                if (!nodes.isEmpty()) {
                    StringBuilder padding = new StringBuilder();
                    for (int i = 0; i < depth; i++) {
                        padding.append("  ");
                    }
                    sb.append(nodes.stream()
                            .map(node -> node.toString(depth + 1))
                            .collect(joining(",\n", "[\n", "\n" + padding + "]")));

                } else {
                    sb.append("[]");
                }
            }
            sb.append("}");
            return sb;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o)
                return true;
            if (o == null || getClass() != o.getClass())
                return false;
            Node node = (Node) o;
            return start == node.start &&
                    end == node.end &&
                    type == node.type &&
                    Objects.equals(nodes, node.nodes) &&
                    Objects.equals(token, node.token);
        }

        @Override
        public int hashCode() {
            return Objects.hash(type, nodes, token, start, end);
        }

    }

    static final class Token implements Located {

        final String text;
        final TokenType type;
        final int start;
        final int end;

        Token(String text, TokenType type, int start, int end) {
            this.text = requireNonNull(text);
            this.type = requireNonNull(type);
            this.start = start;
            this.end = end;
        }

        static boolean canEscape(Integer token) {
            if (Character.isWhitespace(token)) {
                return true;
            }
            switch (token) {
                case (int) escapeCharacter:
                case (int) alternationCharacter:
                case (int) beginParameterCharacter:
                case (int) endParameterCharacter:
                case (int) beginOptionalCharacter:
                case (int) endOptionalCharacter:
                    return true;
            }
            return false;
        }

        static TokenType typeOf(Integer token) {
            if (Character.isWhitespace(token)) {
                return TokenType.WHITE_SPACE;
            }
            switch (token) {
                case (int) alternationCharacter:
                    return TokenType.ALTERNATION;
                case (int) beginParameterCharacter:
                    return TokenType.BEGIN_PARAMETER;
                case (int) endParameterCharacter:
                    return TokenType.END_PARAMETER;
                case (int) beginOptionalCharacter:
                    return TokenType.BEGIN_OPTIONAL;
                case (int) endOptionalCharacter:
                    return TokenType.END_OPTIONAL;
            }
            return TokenType.TEXT;
        }

        static boolean isEscapeCharacter(int token) {
            return token == escapeCharacter;
        }

        public int start() {
            return start;
        }

        public int end() {
            return end;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o)
                return true;
            if (o == null || getClass() != o.getClass())
                return false;
            Token token = (Token) o;
            return start == token.start &&
                    end == token.end &&
                    text.equals(token.text) &&
                    type == token.type;
        }

        @Override
        public int hashCode() {
            return Objects.hash(start, end, text, type);
        }

        @Override
        public String toString() {
            return new StringJoiner(", ", "{", "}")
                    .add("\"type\": \"" + type + "\"")
                    .add("\"start\": " + start)
                    .add("\"end\": " + end)
                    .add("\"text\": \"" + text + "\"")
                    .toString();
        }

        enum TokenType {
            START_OF_LINE,
            END_OF_LINE,
            WHITE_SPACE,
            BEGIN_OPTIONAL("" + beginOptionalCharacter, "optional text"),
            END_OPTIONAL("" + endOptionalCharacter, "optional text"),
            BEGIN_PARAMETER("" + beginParameterCharacter, "a parameter"),
            END_PARAMETER("" + endParameterCharacter, "a parameter"),
            ALTERNATION("" + alternationCharacter, "alternation"),
            TEXT;

            private final String symbol;
            private final String purpose;

            TokenType() {
                this(null, null);
            }

            TokenType(String symbol, String purpose) {
                this.symbol = symbol;
                this.purpose = purpose;
            }

            String purpose() {
                return requireNonNull(purpose, name() + " does not have a purpose");
            }

            String symbol() {
                return requireNonNull(symbol, name() + " does not have a symbol");
            }
        }

    }

}
