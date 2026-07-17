defmodule Varar.CucumberExpressions.TokenizerTest do
  use ExUnit.Case, async: true

  alias Varar.CucumberExpressions.{Testdata, Token, Tokenizer}

  for {name, fixture} <- Testdata.load("cucumber-expression/tokenizer") do
    @fixture fixture
    test "tokenizes #{name}" do
      fixture = @fixture
      expression = fixture["expression"]

      case fixture do
        %{"exception" => expected} ->
          assert {:error, error} = Tokenizer.tokenize(expression)
          assert Exception.message(error) == expected

        %{"expected_tokens" => expected} ->
          assert {:ok, tokens} = Tokenizer.tokenize(expression)
          assert Enum.map(tokens, &token_to_map/1) == expected
      end
    end
  end

  defp token_to_map(%Token{type: type, text: text, start: start, end: end_}) do
    %{"type" => Token.type_string(type), "start" => start, "end" => end_, "text" => text}
  end
end
