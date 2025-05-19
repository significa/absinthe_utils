defmodule AbsintheUtils.Middleware.ArgLoader do
  @moduledoc """
  Absinthe middleware for loading entities in `field` arguments.

  This middleware should be defined before `resolve`. It will manipulate the arguments
  before they are passed to the resolver function.

  As configuration it accepts a map of original argument names (or path) to a keyword list, containing:

  - `new_name`: the new key to push the loaded entity into, can be a list of atoms
    to push the entity into a nested map.
    (optional, defaults to the argument name - the key of the map configuration).
  - `load_function`: the function used to load the argument into an entity.
    As an input accepts two arguments:
    - `context`: the context of the current resolution (prior to any modifications of the current middleware).
    - `input_value`: the value received in the value of `argument_name`.
    The function should return the entity or a list of entities.
    `nil` or an empty list when not found .
  - `nil_is_not_found`: whether to consider `nil` as a not found value.
    (optional, defaults to `true`).

  ## Examples

  ```
  query do
    field :user, :user do
      arg(:id, :id)

      # Add the middleware before your resolver
      middleware(
        ArgLoader,
        %{
          id: [
            new_name: :user,
            load_function: fn _context, id ->
              get_user_by_id(id)
            end,
            nil_is_not_found: false
          ]
        }
      )

      resolve(fn _, arguments, _ ->
        {:ok, Map.get(arguments, :user)}
      end)
    end
  ```

  This will define a `user` query that accepts an `id` input. Before calling the resolver,

  ### List of entities

  `ArgLoader` can also be used to load a `list_of` arguments:

  ```
  query do
    field :users, non_null(list_of(:user)) do
      arg(:ids, non_null(list_of(:id)))

      middleware(
        ArgLoader,
        %{
          ids: [
            new_name: :users,
            load_function: fn _context, ids ->
              ids
              |> get_users_by_id()
              |> AbsintheUtils.Helpers.Sorting.sort_alike(ids, & &1.id)
            end
          ]
        }
      )

      resolve(fn _, params, _ ->
        {:ok, Map.get(params, :users)}
      end)
    end
  end
  ```

  ### Deep nested arguments

  Using `ArgLoader` to load and rename deep nested arguments:

  ```
  input_object :complex_input_object do
    field(:user_id, :id)
  end

  query do
    field :users, :boolean do
      arg(:input, :complex_input_object)

      middleware(
        ArgLoader,
        %{
          [:input, :user_id] => [
            new_name: [:loaded_entities, :user],
            load_function: fn _context, user_id ->
              get_user_by_id(user_id)
            end
          ]
        }
      )

      resolve(fn _, params, _ ->
        # params.loaded_entities.user will contain the loaded user
        {:ok, true}
      end)
    end
  end
  ```


  Note the use of `AbsintheUtils.Helpers.Sorting.sort_alike/2` to ensure the returned list of
  entities from the repository is sorted according to the user's input.
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution
  alias AbsintheUtils.Helpers.Errors
  alias AbsintheUtils.Internal.MapHelpers

  @impl true
  def call(%Resolution{state: :resolved} = resolution, _) do
    resolution
  end

  @impl true
  def call(
        %Resolution{arguments: arguments} = resolution,
        opts
      ) do
    {arguments, not_found_arguments} =
      opts
      |> Enum.reduce(
        {arguments, []},
        fn {argument_name, argument_opts}, {arguments, not_found_arguments} ->
          case load_entities(
                 resolution,
                 arguments,
                 argument_name,
                 argument_opts
               ) do
            :not_found ->
              {
                arguments,
                [argument_name | not_found_arguments]
              }

            arguments ->
              {
                arguments,
                not_found_arguments
              }
          end
        end
      )

    if Enum.empty?(not_found_arguments) do
      %{
        resolution
        | arguments: arguments
      }
    else
      arg_names =
        not_found_arguments
        |> Enum.map_join(", ", fn arg_name ->
          arg_name
          |> to_string()
          |> Absinthe.Utils.camelize(lower: true)
        end)

      Errors.put_error(
        resolution,
        "The entity(ies) provided in the following arg(s), could not be found: #{arg_names}",
        "NOT_FOUND"
      )
    end
  end

  defp load_entities(original_resolution, arguments, argument_name, opts)
       when is_atom(argument_name) do
    load_entities(original_resolution, arguments, [argument_name], opts)
  end

  defp load_entities(original_resolution, arguments, argument_keys_path, opts)
       when is_list(argument_keys_path) do
    case MapHelpers.safe_pop_in(arguments, argument_keys_path) do
      {argument_value, popped_arguments} ->
        case call_load_function(
               original_resolution,
               opts,
               argument_value
             ) do
          :not_found ->
            :not_found

          result ->
            push_to_keys_path =
              Keyword.get(opts, :new_name, argument_keys_path)
              |> List.wrap()

            MapHelpers.recursive_put_in(
              popped_arguments,
              push_to_keys_path,
              result
            )
        end

      :error ->
        arguments
    end
  end

  defp load_entities(_original_resolution, arguments, _argument_name, _opts) do
    arguments
  end

  defp call_load_function(original_resolution, opts, input_value) do
    nil_is_not_found = Keyword.get(opts, :nil_is_not_found, true)
    load_function = Keyword.fetch!(opts, :load_function)

    case load_function.(original_resolution, input_value) do
      nil when nil_is_not_found ->
        :not_found

      nil ->
        nil

      entities when is_list(entities) and is_list(input_value) ->
        entities = if nil_is_not_found, do: Enum.reject(entities, &is_nil/1), else: entities

        if length(entities) != length(input_value) do
          :not_found
        else
          entities
        end

      value ->
        value
    end
  end
end
