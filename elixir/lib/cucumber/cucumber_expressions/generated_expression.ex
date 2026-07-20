defmodule Cucumber.CucumberExpressions.GeneratedExpression do
  @moduledoc """
  A Cucumber Expression suggested by `Cucumber.CucumberExpressions.CucumberExpressionGenerator`,
  along with the parameter types it references.
  """

  @enforce_keys [:source, :parameter_types]
  defstruct [:source, :parameter_types]

  @type t :: %__MODULE__{
          source: String.t(),
          parameter_types: [Cucumber.CucumberExpressions.ParameterType.t()]
        }

  @doc false
  def new(template, parameter_types) do
    %__MODULE__{
      source: interpolate(template, Enum.map(parameter_types, & &1.name)),
      parameter_types: parameter_types
    }
  end

  @doc """
  Suggested parameter names for a snippet: the type names, numbered from the
  second occurrence (`int`, `int2`, ...).
  """
  def parameter_names(%__MODULE__{parameter_types: parameter_types}) do
    {names, _counts} =
      Enum.map_reduce(parameter_types, %{}, fn parameter_type, counts ->
        count = Map.get(counts, parameter_type.name, 0) + 1
        name = if count == 1, do: parameter_type.name, else: "#{parameter_type.name}#{count}"
        {name, Map.put(counts, parameter_type.name, count)}
      end)

    names
  end

  # The template uses %s placeholders and %% for literal % (sprintf-style,
  # like the other ports).
  defp interpolate(template, names), do: interpolate(template, names, [])

  defp interpolate("", _names, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp interpolate("%%" <> rest, names, acc), do: interpolate(rest, names, ["%" | acc])

  defp interpolate("%s" <> rest, [name | names], acc), do: interpolate(rest, names, [name | acc])

  defp interpolate(<<c::utf8, rest::binary>>, names, acc) do
    interpolate(rest, names, [<<c::utf8>> | acc])
  end
end
