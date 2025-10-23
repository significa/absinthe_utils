defmodule AbsintheUtils.Middleware.MutuallyExclusiveInputs do
  @moduledoc """
  Absinthe middleware for validating mutually exclusive input arguments,
  so your code doesn't have to.

  ## Example Usage

  Simple multiple `arg`s:

  ```
  field :example_query_with_two_args, :example_result do
    arg(:arg_one, :string)
    arg(:arg_two, :string)

    middleware(
      MutuallyExclusiveInputs,
      fields: [:arg_one, :arg_two],
      is_required: true
    )

    resolve(&sample_resolver/3)
  end
  ```

  Nested input object fields:

  ```
  object :example_input do
    field :field_one, :string
    field :field_two, :string
    field :field_three, :string
  end

  field :example_query_with_nested_inputs, :example_result do
    arg(:input, :example_input)

    middleware(
      MutuallyExclusiveInputs,
      fields: [
        [:input, :field_one],
        [:input, :field_two],
        [:input, :field_three]
      ],
      is_required: true
    )

    resolve(&MyApp.Resolvers.ExampleResolver.example_query/3)
  end
  ```
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  alias AbsintheUtils.Helpers.Errors

  @impl true
  def call(%Resolution{arguments: arguments} = resolution, config) do
    is_required = Keyword.get(config, :is_required, false)

    # Convert single input field paths to lists, consider if this Dev-X helper is worth it
    input_field_paths =
      config
      |> Keyword.fetch!(:fields)
      |> Enum.map(fn
        field_path when is_atom(field_path) -> [field_path]
        field_path when is_list(field_path) -> field_path
      end)

    arguments_present_count =
      Enum.count_until(
        input_field_paths,
        fn input_field_path ->
          has_key?(arguments, input_field_path)
        end,
        2
      )

    cond do
      is_required and arguments_present_count != 1 ->
        put_error(resolution, input_field_paths, :required_mutually_exclusive_arg_violation)

      not is_required and arguments_present_count > 1 ->
        put_error(resolution, input_field_paths, :mutually_exclusive_arg_violation)

      true ->
        resolution
    end
  end

  @spec has_key?(map :: map(), keys :: [atom()]) :: boolean()
  def has_key?(map, _) when not is_map(map), do: false
  def has_key?(map, [key]), do: Map.has_key?(map, key)
  def has_key?(map, [key | tail]), do: Map.has_key?(map, key) and has_key?(map[key], tail)

  defp put_error(resolution, input_field_paths, :mutually_exclusive_arg_violation) do
    stringified_input_field_paths = get_input_field_paths_string(input_field_paths)

    Errors.put_error(
      resolution,
      "Only one of the arguments #{stringified_input_field_paths} can be provided at a time",
      %{
        code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
        field_paths: input_field_paths
      }
    )
  end

  defp put_error(resolution, input_field_paths, :required_mutually_exclusive_arg_violation) do
    stringified_input_field_paths = get_input_field_paths_string(input_field_paths)

    Errors.put_error(
      resolution,
      "Exactly one of the following arguments must be provided: #{stringified_input_field_paths}",
      %{
        code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
        field_paths: input_field_paths
      }
    )
  end

  defp get_input_field_paths_string(input_field_paths) do
    Enum.map_join(
      input_field_paths,
      ", ",
      &get_input_field_path_string/1
    )
  end

  defp get_input_field_path_string(input_field_path) do
    Enum.map_join(
      input_field_path,
      ".",
      fn arg_name ->
        arg_name
        |> to_string()
        |> Absinthe.Utils.camelize(lower: true)
      end
    )
  end
end
