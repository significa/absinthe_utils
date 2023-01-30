defmodule AbsintheUtils.Helpers.SortTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Helpers.Sorted

  describe "sort_alike" do
    test "empty lists" do
      assert [] === Sorted.sort_alike([], [])
    end

    test "unsorted empty" do
      assert [] === Sorted.sort_alike([], [1, 2, 3])
    end

    test "unsorted contains unknown elements" do
      assert_raise KeyError, fn ->
        Sorted.sort_alike([8], [1, 2, 3])
      end
    end

    test "sorted contains more elements" do
      assert [1] === Sorted.sort_alike([1], [1, 2, 3])
    end

    test "all elements match" do
      assert [2, 3, 1] === Sorted.sort_alike([1, 2, 3], [2, 3, 1])
    end

    test "with unsorted mapper" do
      assert [
               %{id: 3},
               %{id: 1},
               %{id: 2}
             ] ===
               Sorted.sort_alike(
                 [
                   %{id: 1},
                   %{id: 2},
                   %{id: 3}
                 ],
                 [3, 1, 2],
                 & &1.id
               )
    end

    test "with both mapper" do
      assert [
               %{id: 2},
               %{id: 3},
               %{id: 1}
             ] ===
               Sorted.sort_alike(
                 [
                   %{id: 1},
                   %{id: 2},
                   %{id: 3}
                 ],
                 [
                   %{id: 2},
                   %{id: 3},
                   %{id: 1}
                 ],
                 & &1.id,
                 & &1.id
               )
    end
  end

  describe "_map_element_to_index" do
    test "empty list" do
      assert %{} === Sorted._map_element_to_index([])
    end

    test "no mapper" do
      assert %{
               1 => 0,
               2 => 1,
               3 => 2
             } === Sorted._map_element_to_index([1, 2, 3])
    end

    test "with mapper" do
      assert %{
               "John" => 0,
               "Ally" => 1,
               "Sam" => 2
             } ===
               Sorted._map_element_to_index(
                 [
                   %{name: "John"},
                   %{name: "Ally"},
                   %{name: "Sam"}
                 ],
                 & &1.name
               )
    end
  end
end
