package io.cucumber.cucumberexpressions;

import org.jspecify.annotations.Nullable;

import java.util.Objects;
import java.util.StringJoiner;

import static java.util.Objects.requireNonNull;

final class Token implements Located {

    private static final char escapeCharacter = '\\';
    private static final char alternationCharacter = '/';
    private static final char beginParameterCharacter = '{';
    private static final char endParameterCharacter = '}';
    private static final char beginOptionalCharacter = '(';
    private static final char endOptionalCharacter = ')';

    final String text;
    final Type type;
    final int start;
    final int end;

    Token(String text, Type type, int start, int end) {
        this.text = requireNonNull(text);
        this.type = requireNonNull(type);
        this.start = start;
        this.end = end;
    }

    static boolean canEscape(Integer token) {
        if (Character.isWhitespace(token)) {
            return true;
        }
        return switch (token) {
            case (int) escapeCharacter,
                 (int) alternationCharacter,
                 (int) beginParameterCharacter,
                 (int) endParameterCharacter,
                 (int) beginOptionalCharacter,
                 (int) endOptionalCharacter -> true;
            default -> false;
        };
    }

    static Type typeOf(Integer token) {
        if (Character.isWhitespace(token)) {
            return Type.WHITE_SPACE;
        }
        return switch (token) {
            case (int) alternationCharacter -> Type.ALTERNATION;
            case (int) beginParameterCharacter -> Type.BEGIN_PARAMETER;
            case (int) endParameterCharacter -> Type.END_PARAMETER;
            case (int) beginOptionalCharacter -> Type.BEGIN_OPTIONAL;
            case (int) endOptionalCharacter -> Type.END_OPTIONAL;
            default -> Type.TEXT;
        };
    }

    static boolean isEscapeCharacter(int token) {
        return token == escapeCharacter;
    }

    @Override
    public int start() {
        return start;
    }

    @Override
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

    enum Type {
        START_OF_LINE,
        END_OF_LINE,
        WHITE_SPACE,
        BEGIN_OPTIONAL("" + beginOptionalCharacter, "optional text"),
        END_OPTIONAL("" + endOptionalCharacter, "optional text"),
        BEGIN_PARAMETER("" + beginParameterCharacter, "a parameter"),
        END_PARAMETER("" + endParameterCharacter, "a parameter"),
        ALTERNATION("" + alternationCharacter, "alternation"),
        TEXT;

        private final @Nullable String symbol;
        private final @Nullable String purpose;

        Type() {
            this(null, null);
        }

        Type(@Nullable String symbol, @Nullable String purpose) {
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
