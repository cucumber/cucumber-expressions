defmodule Cucumber.CucumberExpressions.TreeRegexp do
  @moduledoc """
  A regexp paired with the tree structure of its capture groups, so a match
  can be presented as a `Cucumber.CucumberExpressions.Group` tree instead of a
  flat list.

  The group tree is derived by walking the regexp source: capturing groups
  become nodes, non-capturing constructs (`(?:`, lookarounds, inline flags)
  are transparent. Named capture groups are not supported and raise
  `Cucumber.CucumberExpressions.Error`.
  """

  alias Cucumber.CucumberExpressions.{Error, Group, GroupBuilder}

  @enforce_keys [:regex, :group_builder]
  defstruct [:regex, :group_builder]

  @type t :: %__MODULE__{regex: Regex.t(), group_builder: GroupBuilder.t()}

  @doc """
  Builds a TreeRegexp from a `Regex` or a source string. Raises
  `Cucumber.CucumberExpressions.Error` for named capture groups.
  """
  @spec new!(Regex.t() | String.t()) :: t()
  def new!(source) when is_binary(source), do: new!(Regex.compile!(source, "u"))

  def new!(%Regex{} = regex) do
    source_chars = String.to_charlist(Regex.source(regex))
    %__MODULE__{regex: regex, group_builder: create_group_builder(source_chars)}
  end

  @doc "Matches `text`, returning the root `Group` (the full match) or `nil`."
  @spec match(t(), String.t()) :: Group.t() | nil
  def match(%__MODULE__{regex: regex, group_builder: group_builder}, text) do
    case Regex.run(regex, text, return: :index) do
      nil ->
        nil

      indices ->
        total = GroupBuilder.count_groups(group_builder) + 1
        indices = indices ++ List.duplicate({-1, 0}, total - length(indices))
        {group, []} = GroupBuilder.build(group_builder, text, indices)
        group
    end
  end

  defp create_group_builder(source_chars) do
    walk(source_chars, 0, source_chars, [%GroupBuilder{}], [], false, false)
  end

  defp walk([], _i, _source, [root], _group_starts, _escaping, _char_class), do: root

  # A direct port of the upstream source walker; kept in one function for
  # fidelity with the other language implementations.
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp walk([c | rest], i, source, stack, group_starts, escaping, char_class) do
    {stack, group_starts, char_class} =
      cond do
        c == ?[ and not escaping ->
          {stack, group_starts, true}

        c == ?] and not escaping ->
          {stack, group_starts, false}

        c == ?( and not escaping and not char_class ->
          builder = %GroupBuilder{capturing: not non_capturing?(source, i)}
          {[builder | stack], [i | group_starts], char_class}

        c == ?) and not escaping and not char_class ->
          [builder, parent | ancestors] = stack
          [group_start | remaining_starts] = group_starts

          parent =
            if builder.capturing do
              group_source =
                source
                |> Enum.slice(group_start + 1, i - group_start - 1)
                |> List.to_string()

              %{parent | children: parent.children ++ [%{builder | source: group_source}]}
            else
              %{parent | children: parent.children ++ builder.children}
            end

          {[parent | ancestors], remaining_starts, char_class}

        true ->
          {stack, group_starts, char_class}
      end

    walk(rest, i + 1, source, stack, group_starts, c == ?\\ and not escaping, char_class)
  end

  defp non_capturing?(source, i) do
    cond do
      # The regex is valid, so no bounds check is required.
      Enum.at(source, i + 1) != ?? ->
        # (X)
        false

      Enum.at(source, i + 2) != ?< ->
        # (?:X), (?idmsuxU-idmsuxU), (?idmsux-idmsux:X), (?=X), (?!X), (?>X)
        true

      Enum.at(source, i + 3) in [?=, ?!] ->
        # (?<=X), (?<!X)
        true

      true ->
        # (?<name>X)
        raise Error,
          message:
            "Named capture groups are not supported. " <>
              "See https://github.com/cucumber/cucumber/issues/329"
    end
  end
end
