defmodule Cucumber.CucumberExpressions.ParameterTypeMatcher do
  @moduledoc false

  # Finds where a parameter type's regexp matches inside a step text, used by
  # the generator. Positions are byte offsets into the text; `advance_to/2`
  # only probes codepoint boundaries.

  defstruct [:parameter_type, :regexp, :text, :offsets, :match]

  @word_boundary ~r/\p{Z}|\p{P}|\p{S}/u

  def new(parameter_type, regexp, text, match_position) do
    %__MODULE__{
      parameter_type: parameter_type,
      regexp: regexp,
      text: text,
      offsets: codepoint_offsets(text)
    }
    |> probe(match_position)
  end

  # Re-probes an existing matcher at `match_position`, reusing its cached
  # codepoint offsets rather than re-scanning the text.
  defp probe(%__MODULE__{regexp: regexp, text: text} = matcher, match_position) do
    match =
      with true <- match_position <= byte_size(text),
           [{match_start, match_length}, {group_start, group_length} | _] <-
             Regex.run(regexp, text, offset: match_position, return: :index) do
        %{
          start: match_start,
          length: match_length,
          group: binary_part(text, group_start, group_length)
        }
      else
        _ -> nil
      end

    %{matcher | match: match}
  end

  def find?(%__MODULE__{match: nil}), do: false
  def find?(%__MODULE__{match: %{group: group}}), do: group != ""

  @doc """
  Returns the first matcher at or after `new_match_position` whose match is a
  full word,
  or a matcher positioned at the end of the text.
  """
  def advance_to(%__MODULE__{text: text, offsets: offsets} = matcher, new_match_position) do
    offsets
    |> Enum.drop_while(&(&1 < new_match_position))
    |> Enum.find_value(fn offset ->
      candidate = probe(matcher, offset)
      if find?(candidate) and full_word?(candidate), do: candidate
    end)
    |> Kernel.||(probe(matcher, byte_size(text)))
  end

  def sorts_before?(%__MODULE__{match: a}, %__MODULE__{match: b}) do
    if a.start != b.start do
      a.start < b.start
    else
      String.length(a.group) >= String.length(b.group)
    end
  end

  def same_rank?(%__MODULE__{match: a}, %__MODULE__{match: b}) do
    a.start == b.start and String.length(a.group) == String.length(b.group)
  end

  defp full_word?(%__MODULE__{text: text, match: %{start: start, length: length}}) do
    boundary_before?(text, start) and boundary_after?(text, start + length)
  end

  defp boundary_before?(_text, 0), do: true

  defp boundary_before?(text, match_start) do
    boundary?(String.last(binary_part(text, 0, match_start)))
  end

  defp boundary_after?(text, match_end) when match_end == byte_size(text), do: true

  defp boundary_after?(text, match_end) do
    boundary?(String.first(binary_part(text, match_end, byte_size(text) - match_end)))
  end

  defp boundary?(char), do: Regex.match?(@word_boundary, char)

  defp codepoint_offsets(text) do
    {offsets, _} =
      text
      |> String.codepoints()
      |> Enum.map_reduce(0, fn codepoint, offset ->
        {offset, offset + byte_size(codepoint)}
      end)

    offsets
  end
end
