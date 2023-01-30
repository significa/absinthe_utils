defmodule AbsintheUtils.Helpers.Sorted do
  def sort_alike(
        unsorted_enumerable,
        sorted_enumerable,
        unsorted_enumerable_mapper \\ & &1,
        sorted_enumerable_mapper \\ & &1
      ) do
    value_to_index =
      sorted_enumerable
      |> _map_element_to_index(sorted_enumerable_mapper)

    unsorted_enumerable
    |> Enum.sort_by(fn element ->
      Map.fetch!(
        value_to_index,
        unsorted_enumerable_mapper.(element)
      )
    end)
  end

  def _map_element_to_index(enumerable, mapper \\ & &1) do
    enumerable
    |> Enum.map(mapper)
    |> Enum.with_index()
    |> Map.new(fn {element, index} -> {element, index} end)
  end
end
