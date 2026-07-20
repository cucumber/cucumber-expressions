defmodule Cucumber.CucumberExpressions.CucumberExpressionGenerator do
  @moduledoc """
  Generates Cucumber Expression suggestions for a step text — the machinery
  behind "undefined step" snippets.
  """

  alias Cucumber.CucumberExpressions.CombinatorialGeneratedExpressionFactory
  alias Cucumber.CucumberExpressions.GeneratedExpression
  alias Cucumber.CucumberExpressions.ParameterType
  alias Cucumber.CucumberExpressions.ParameterTypeMatcher
  alias Cucumber.CucumberExpressions.ParameterTypeRegistry

  @doc """
  Generates suggested expressions for `text`, most specific first.
  """
  @spec generate_expressions(ParameterTypeRegistry.t(), String.t()) :: [GeneratedExpression.t()]
  def generate_expressions(%ParameterTypeRegistry{} = registry, text) do
    parameter_type_matchers = create_parameter_type_matchers(registry, text)

    {expression_template, parameter_type_combinations} =
      scan(parameter_type_matchers, text, 0, "", [])

    CombinatorialGeneratedExpressionFactory.generate_expressions(
      expression_template,
      parameter_type_combinations
    )
  end

  defp scan(parameter_type_matchers, text, pos, expression_template, parameter_type_combinations) do
    matching_parameter_type_matchers =
      parameter_type_matchers
      |> Enum.map(&ParameterTypeMatcher.advance_to(&1, pos))
      |> Enum.filter(&ParameterTypeMatcher.find?/1)

    case Enum.sort(matching_parameter_type_matchers, &ParameterTypeMatcher.sorts_before?/2) do
      [] ->
        finish(expression_template, text, pos, parameter_type_combinations)

      [best_parameter_type_matcher | _] = sorted ->
        # Collect the parameter types matching_parameter_type_matchers equally well, without
        # duplicates (a type with several regexps has several parameter_type_matchers).
        # Preferential types are listed first — users are most likely to want
        # those.
        parameter_types =
          sorted
          |> Enum.take_while(&ParameterTypeMatcher.same_rank?(&1, best_parameter_type_matcher))
          |> Enum.map(& &1.parameter_type)
          |> Enum.uniq()
          |> Enum.sort(&ParameterType.compare/2)

        parameter_type_combinations = [parameter_types | parameter_type_combinations]

        expression_template =
          expression_template <>
            escape(binary_part(text, pos, best_parameter_type_matcher.match.start - pos)) <>
            "{%s}"

        pos =
          best_parameter_type_matcher.match.start +
            byte_size(best_parameter_type_matcher.match.group)

        if pos >= byte_size(text) do
          finish(expression_template, text, pos, parameter_type_combinations)
        else
          scan(
            parameter_type_matchers,
            text,
            pos,
            expression_template,
            parameter_type_combinations
          )
        end
    end
  end

  defp finish(expression_template, text, pos, parameter_type_combinations) do
    tail =
      if pos >= byte_size(text) do
        ""
      else
        binary_part(text, pos, byte_size(text) - pos)
      end

    # `parameter_type_combinations` is accumulated by prepending, so reverse it back to
    # left-to-right expression_template order here.
    {expression_template <> escape(tail), Enum.reverse(parameter_type_combinations)}
  end

  defp create_parameter_type_matchers(registry, text) do
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
