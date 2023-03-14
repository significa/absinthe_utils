defmodule AbsintheUtils.Helpers.SortingTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Helpers.Sort

  doctest AbsintheUtils.Helpers.Sort

  describe "sort_alike" do
    test "empty lists" do
      assert [] === Sort.sort_alike([], [])
    end

    test "unsorted empty" do
      assert [nil, nil, nil] === Sort.sort_alike([], [1, 2, 3])
    end

    test "unsorted contains unknown elements" do
      assert [nil, nil, nil] === Sort.sort_alike([8], [1, 2, 3])
    end

    test "sorted contains more elements than unsorted" do
      assert [nil, 2, nil] === Sort.sort_alike([2], [1, 2, 3])
    end

    test "all elements match" do
      assert [2, 3, 1] === Sort.sort_alike([1, 2, 3], [2, 3, 1])
    end

    test "unsorted contains duplicates" do
      assert [:a, :b] === Sort.sort_alike([:b, :a, :b], [:a, :b])
    end

    test "sorted contains duplicates" do
      assert [:b, :a, :b] === Sort.sort_alike([:b, :a], [:b, :a, :b])
    end

    test "with unsorted mapper" do
      assert [
               %{id: 3},
               %{id: 1},
               %{id: 2}
             ] ===
               Sort.sort_alike(
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
               Sort.sort_alike(
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
end
