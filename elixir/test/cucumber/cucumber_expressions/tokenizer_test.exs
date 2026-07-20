defmodule Cucumber.CucumberExpressions.TokenizerTest do
  use ExUnit.Case, async: true

  alias Cucumber.CucumberExpressions.{Testdata, Token, Tokenizer}

  for {name, fixture} <- Testdata.load("cucumber-expression/tokenizer") do
    @fixture fixture
    if Map.has_key?(fixture, "exception") do
      test "rejects #{name}" do
        %{"expression" => expression, "exception" => expected} = @fixture
        assert {:error, error} = Tokenizer.tokenize(expression)
        assert Exception.message(error) == expected
      end
    else
      test "tokenizes #{name}" do
        %{"expression" => expression, "expected_tokens" => expected} = @fixture
        assert {:ok, tokens} = Tokenizer.tokenize(expression)
        assert Enum.map(tokens, &token_to_map/1) == expected
      end
    end
  end

  defp token_to_map(%Token{type: type, text: text, start: start, end: end_}) do
    %{"type" => Token.type_string(type), "start" => start, "end" => end_, "text" => text}
  end
end
