defmodule Varar.CucumberExpressions.Generator do
  @moduledoc """
  Generates Cucumber Expression suggestions for a step text — the machinery
  behind "undefined step" snippets.
  """

  alias Varar.CucumberExpressions.{
    CombinatorialGeneratedExpressionFactory,
    GeneratedExpression,
    ParameterType,
    ParameterTypeMatcher,
    ParameterTypeRegistry
  }

  @doc """
  Generates suggested expressions for `text`, most specific first.
  """
  @spec generate_expressions(ParameterTypeRegistry.t(), String.t()) :: [GeneratedExpression.t()]
  def generate_expressions(%ParameterTypeRegistry{} = registry, text) do
    matchers = create_matchers(registry, text)
    {template, combinations} = scan(matchers, text, 0, "", [])
    CombinatorialGeneratedExpressionFactory.generate_expressions(template, combinations)
  end

  defp scan(matchers, text, pos, template, combinations) do
    matching =
      matchers
      |> Enum.map(&ParameterTypeMatcher.advance_to(&1, pos))
      |> Enum.filter(&ParameterTypeMatcher.find?/1)

    case Enum.sort(matching, &ParameterTypeMatcher.sorts_before?/2) do
      [] ->
        finish(template, text, pos, combinations)

      [best | _] = sorted ->
        # Collect the parameter types matching equally well, without
        # duplicates (a type with several regexps has several matchers).
        # Preferential types are listed first — users are most likely to want
        # those.
        parameter_types =
          sorted
          |> Enum.take_while(&ParameterTypeMatcher.same_rank?(&1, best))
          |> Enum.map(& &1.parameter_type)
          |> Enum.uniq()
          |> Enum.sort(&ParameterType.compare/2)

        combinations = combinations ++ [parameter_types]

        template =
          template <> escape(binary_part(text, pos, best.match.start - pos)) <> "{%s}"

        pos = best.match.start + byte_size(best.match.group)

        if pos >= byte_size(text) do
          finish(template, text, pos, combinations)
        else
          scan(matchers, text, pos, template, combinations)
        end
    end
  end

  defp finish(template, text, pos, combinations) do
    tail =
      if pos >= byte_size(text) do
        ""
      else
        binary_part(text, pos, byte_size(text) - pos)
      end

    {template <> escape(tail), combinations}
  end

  defp create_matchers(registry, text) do
    for parameter_type <- ParameterTypeRegistry.parameter_types(registry),
        parameter_type.use_for_snippets,
        regexp <- parameter_type.regexps do
      ParameterTypeMatcher.new(
        parameter_type,
        Regex.compile!("(" <> regexp <> ")", "u"),
        text,
        0
      )
    end
  end

  defp escape(string) do
    string
    |> String.replace("%", "%%")
    |> String.replace("(", "\\(")
    |> String.replace("{", "\\{")
    |> String.replace("/", "\\/")
  end
end
