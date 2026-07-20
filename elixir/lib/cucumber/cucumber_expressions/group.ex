defmodule Cucumber.CucumberExpressions.Group do
  @moduledoc """
  A matched capture group, possibly with nested child groups.

  `start` and `end` are codepoint offsets into the matched text; all three of
  `value`, `start` and `end` are `nil` when the group did not participate in
  the match (e.g. an unmatched optional).
  """

  defstruct [:value, :start, :end, :children]

  @type t :: %__MODULE__{
          value: String.t() | nil,
          start: non_neg_integer() | nil,
          end: non_neg_integer() | nil,
          children: [t()] | nil
        }

  @doc """
  The values passed to a parameter type's transformer: the direct children's
  values, or this group's own value for a leaf group.
  """
  def values(%__MODULE__{value: value, children: nil}), do: [value]
  def values(%__MODULE__{children: children}), do: Enum.map(children, & &1.value)
end
