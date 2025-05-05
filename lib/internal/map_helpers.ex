defmodule AbsintheUtils.Internal.MapHelpers do
  @moduledoc """
  Helper for nested map manipulations.
  """

  @doc """
  Pop a key from a nested map, if successful returns a tuple of:
   - the popped value
   - the modified map, without the popped key
  OR if the key is not found, returns :error

  ## Examples

      iex> MapHelpers.safe_pop_in(%{a: 1}, [:a])
      {1, %{}}

      iex> MapHelpers.safe_pop_in(%{a: 1}, :a)
      {1, %{}}

      iex> MapHelpers.safe_pop_in(%{a: 1}, [:invalid])
      :error

      iex> MapHelpers.safe_pop_in(%{a: %{b: 1}}, [:a, :b])
      {1, %{a: %{}}}

      iex> MapHelpers.safe_pop_in(%{a: %{b: 1}}, [:a, :invalid])
      :error

      iex> MapHelpers.safe_pop_in(%{}, [:a])
      :error

      iex> MapHelpers.safe_pop_in(%{a: 1}, [])
      :error

      iex> MapHelpers.safe_pop_in(%{a: 1}, [:a, :b, :c])
      :error

      iex> MapHelpers.safe_pop_in(%{a: 1, b: %{c: 2}}, [:b])
      {%{c: 2}, %{a: 1}}

      iex> MapHelpers.safe_pop_in(%{"a" => 1}, ["a"])
      {1, %{}}
  """
  def safe_pop_in(map, [last_key]) do
    safe_pop_in(map, last_key)
  end

  def safe_pop_in(map, [key | rest]) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        case safe_pop_in(value, rest) do
          {popped_value, new_value} ->
            {popped_value, Map.put(map, key, new_value)}

          :error ->
            :error
        end

      :error ->
        :error
    end
  end

  def safe_pop_in(map, last_key) when is_map_key(map, last_key) do
    Map.pop(map, last_key)
  end

  def safe_pop_in(_, _) do
    :error
  end

  @doc """
  Put a value in a tested map, if any of the keys in the keys_path are not found,
  they will be recursively created.

  ## Examples

      iex> MapHelpers.recursive_put_in(%{a: 1}, [:b], 2)
      %{a: 1, b: 2}

      iex> MapHelpers.recursive_put_in(%{}, [:a], 1)
      %{a: 1}

      iex> MapHelpers.recursive_put_in(%{}, :a, 1)
      %{a: 1}
  """

  def recursive_put_in(map, keys_path, _value) when not is_map(map) do
    raise ArgumentError,
          "Cannot put value recursively #{inspect(keys_path)} into: #{inspect(map)}"
  end

  def recursive_put_in(map, keys_path, value) when is_atom(keys_path) do
    recursive_put_in(map, [keys_path], value)
  end

  def recursive_put_in(map, [key], value) do
    Map.put(map, key, value)
  end

  def recursive_put_in(map, [key | rest], value) do
    current_value = Map.get(map, key, %{})
    updated_value = recursive_put_in(current_value, rest, value)
    Map.put(map, key, updated_value)
  end
end
