defmodule AbsintheUtils.Helpers.Sort do
  @moduledoc """
  Generic sorting utils.
  """

  @doc """
  Sorts an `unsorted_enumerable` based on `sorted_enumerable`.
  `unsorted_enumerable` cannot contain duplicates and
  can only contain elements from `sorted_enumerable`.

  Use mappers to specify getters for each element in the enumerable.

  ## Examples

      iex> Sort.sort_alike([:b, :c, :a], [:a, :b, :c])
      [:a, :b, :c]

  """
  def sort_alike(
        unsorted_enumerable,
        sorted_enumerable,
        unsorted_enumerable_mapper \\ & &1,
        sorted_enumerable_mapper \\ & &1
      ) do
    value_to_index =
      sorted_enumerable
      |> Enum.map(sorted_enumerable_mapper)
      |> map_enum_to_index()

    unsorted_enumerable
    |> Enum.sort_by(fn element ->
      Map.fetch!(
        value_to_index,
        unsorted_enumerable_mapper.(element)
      )
    end)
  end

  @doc """
  Given an enumerable, returns a map of each element
  to the position in the original enumerable (zero based).

  ## Examples

      iex> Sort.map_enum_to_index([:a, :b, :c])
      %{a: 0, b: 1, c: 2}
  """
  @spec map_enum_to_index(list(any)) :: map
  def map_enum_to_index(enumerable) do
    enumerable
    |> Enum.with_index()
    |> Map.new(fn {element, index} -> {element, index} end)
  end
end
