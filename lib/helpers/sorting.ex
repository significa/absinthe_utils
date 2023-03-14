defmodule AbsintheUtils.Helpers.Sorting do
  @moduledoc """
  Generic sorting utils.
  """

  @doc """
  Sorts an `unsorted_enumerable` based on `sorted_enumerable`.
  Use mappers to specify getters for each element in the enumerable,
  for example retrieving the id of a struct.

  ## Examples

      iex> Sorting.sort_alike([:b, :c, :a], [:a, :b, :c])
      [:a, :b, :c]

      iex> Sorting.sort_alike([%{id: 1}, %{id: 2}], [2, 1], & &1.id)
      [%{id: 2}, %{id: 1}]
  """
  def sort_alike(
        unsorted_enumerable,
        sorted_enumerable,
        unsorted_enumerable_mapper \\ & &1,
        sorted_enumerable_mapper \\ & &1
      ) do
    id_to_unsorted_element =
      unsorted_enumerable
      |> Map.new(fn element ->
        {
          unsorted_enumerable_mapper.(element),
          element
        }
      end)

    Enum.map(
      sorted_enumerable,
      fn element ->
        Map.get(
          id_to_unsorted_element,
          sorted_enumerable_mapper.(element)
        )
      end
    )
  end
end
