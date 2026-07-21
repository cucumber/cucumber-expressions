defmodule Cucumber.CucumberExpressions.GroupBuilder do
  @moduledoc """
  The compile-time shape of a regexp's capture groups, built by
  `Cucumber.CucumberExpressions.TreeRegexp`. At match time, `build/3` pairs the
  shape with the flat list of match indices to produce a
  `Cucumber.CucumberExpressions.Group` tree.
  """

  alias Cucumber.CucumberExpressions.Group

  defstruct children: [], capturing: true, source: nil

  @type t :: %__MODULE__{
          children: [t()],
          capturing: boolean(),
          source: String.t() | nil
        }

  @doc "Total number of capturing groups in this builder's subtree."
  def count_groups(%__MODULE__{children: children}) do
    Enum.reduce(children, length(children), fn child, acc -> acc + count_groups(child) end)
  end

  @doc """
  Consumes match indices (a list of `{byte_start, byte_length}` tuples, `{-1, 0}`
  for unparticipating groups) to build the `Group` tree for `text`. Returns
  `{group, remaining_indices}`.
  """
  def build(%__MODULE__{children: children}, text, [own_index | rest]) do
    {built_children, rest} =
      Enum.reduce(children, {[], rest}, fn child, {acc, rest} ->
        {group, rest} = build(child, text, rest)
        {[group | acc], rest}
      end)

    {value, start, end_} = extract(text, own_index)

    group = %Group{
      value: value,
      start: start,
      end: end_,
      children: if(built_children == [], do: nil, else: Enum.reverse(built_children))
    }

    {group, rest}
  end

  defp extract(_text, {-1, _length}), do: {nil, nil, nil}

  defp extract(text, {byte_start, byte_length}) do
    value = binary_part(text, byte_start, byte_length)
    start = String.length(binary_part(text, 0, byte_start))
    {value, start, start + String.length(value)}
  end
end
