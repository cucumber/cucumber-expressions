package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;

import java.util.List;
import java.util.Objects;

import static java.util.Objects.requireNonNull;
import static java.util.stream.Collectors.joining;
import static org.apiguardian.api.API.Status.EXPERIMENTAL;

@API(since = "18.1", status = EXPERIMENTAL)
public final class Node implements Ast.Located {

    private final Type type;
    private final List<Node> nodes;
    private final String token;
    private final int start;
    private final int end;

    Node(Type type, int start, int end, String token) {
        this(type, start, end, null, requireNonNull(token));
    }

    Node(Type type, int start, int end, List<Node> nodes) {
        this(type, start, end, requireNonNull(nodes), null);
    }

    private Node(Type type, int start, int end, List<Node> nodes, String token) {
        this.type = requireNonNull(type);
        this.nodes = nodes;
        this.token = token;
        this.start = start;
        this.end = end;
    }

    public enum Type {
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

    public Type type() {
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
