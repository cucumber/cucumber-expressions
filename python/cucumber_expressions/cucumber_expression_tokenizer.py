from cucumber_expressions.ast import TokenType, Token
from cucumber_expressions.errors import (
    TheEndOfLineCannotBeEscaped,
    CantEscape,
)


class CucumberExpressionTokenizer:
    def __init__(self):
        self.expression: str = ""
        self.buffer: list[int] = []
        self.escaped: int = 0
        self.buffer_start_index: int = 0

    def tokenize(self, expression: str, to_json: bool = False) -> list[Token]:
        self.expression = expression
        tokens = []
        previous_token_type = TokenType.START_OF_LINE
        treat_as_text = False

        codepoints = [ord(c) for c in self.expression]

        if not codepoints:
            tokens.append(Token(TokenType.START_OF_LINE, "", 0, 0))

        for codepoint in codepoints:
            if (not treat_as_text) and Token.is_escape_character(codepoint):
                self.escaped += 1
                treat_as_text = True
                continue

            current_token_type = self.token_type_of(codepoint, treat_as_text)
            treat_as_text = False

            if self.should_create_new_token(previous_token_type, current_token_type):
                token = self.convert_buffer_to_token(previous_token_type)
                previous_token_type = current_token_type
                self.buffer.append(codepoint)
                tokens.append(token)
            else:
                previous_token_type = current_token_type
                self.buffer.append(codepoint)

        if len(self.buffer) > 0:
            token = self.convert_buffer_to_token(previous_token_type)
            tokens.append(token)

        if treat_as_text:
            raise TheEndOfLineCannotBeEscaped(expression)

        tokens.append(
            Token(TokenType.END_OF_LINE, "", len(codepoints), len(codepoints))
        )

        def convert_to_json_format(_tokens: list[Token]) -> list:
            return [
                {
                    "type": t.ast_type.value,
                    "end": t.end,
                    "start": t.start,
                    "text": t.text,
                }
                for t in _tokens
            ]

        return tokens if not to_json else convert_to_json_format(tokens)

    def convert_buffer_to_token(self, token_type: TokenType) -> Token:
        escape_tokens = 0
        if token_type == TokenType.TEXT:
            escape_tokens = self.escaped
            self.escaped = 0

        consumed_index = self.buffer_start_index + len(self.buffer) + escape_tokens
        t = Token(
            token_type,
            "".join([chr(codepoint) for codepoint in self.buffer]),
            self.buffer_start_index,
            consumed_index,
        )
        self.buffer = []
        self.buffer_start_index = consumed_index
        return t

    def token_type_of(self, codepoint: int, treat_as_text) -> TokenType:
        if not treat_as_text:
            return Token.type_of(codepoint)
        elif Token.can_escape(codepoint):
            return TokenType.TEXT
        else:
            raise CantEscape(
                self.expression,
                self.buffer_start_index + len(self.buffer) + self.escaped,
            )

    @staticmethod
    def should_create_new_token(
        previous_token_type: TokenType, current_token_type: TokenType
    ):
        return (current_token_type != previous_token_type) or (
            current_token_type != TokenType.WHITE_SPACE
            and current_token_type != TokenType.TEXT
        )
