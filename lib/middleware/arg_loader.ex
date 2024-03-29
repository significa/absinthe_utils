defmodule AbsintheUtils.Middleware.ArgLoader do
  @moduledoc """
  Absinthe middleware for loading entities in `field` arguments.

  This middleware should be defined before `resolve`. It will manipulate the arguments
  before they are passed to the resolver function.

  As configuration it accepts a map of original argument names to a keyword list, containing:

  - `load_function`: the function used to load the argument into an entity.
    As an input accepts one single argument: the input received in the resolution.
    The function should return the entity, or `nil` when not found.
  - `new_name`: the new name to push the loaded entity into.
    (optional, defaults to the original argument name).

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
            load_function: &get_user_by_id/1
          ]
        }
      )

      resolve(fn _, arguments, _ ->
        {:ok, Map.get(arguments, :user)}
      end)
    end
  ```

  This will define a `user` query that accepts an `id` input. Before calling the resolver,
  it will load the user via `get_user_by_id(id)` into the `user` argument, removing `id`.

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
            load_function: fn ids ->
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

  Note the use of ` AbsintheUtils.Helpers.Sorting.sort_alike/2` to ensure the returned list of
  entities from the repository is sorted according to the user's input.
  """

  @behaviour Absinthe.Middleware

  alias AbsintheUtils.Helpers.Errors

  @impl true
  def call(
        resolution = %{arguments: arguments},
        opts
      ) do
    {arguments, not_found_arguments} =
      opts
      |> Enum.reduce(
        {arguments, []},
        fn {argument_name, opts}, {arguments, not_found_arguments} ->
          case load_entities(
                 arguments,
                 argument_name,
                 opts
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
      Errors.put_error(
        resolution,
        "The entity(ies) provided in the following arg(s), could not be found: " <>
          Enum.join(not_found_arguments, ", "),
        "NOT_FOUND"
      )
    end
  end

  def load_entities(arguments, argument_name, opts)
      when is_map_key(arguments, argument_name) do
    load_function = Keyword.fetch!(opts, :load_function)
    push_to_key = Keyword.get(opts, :new_name, argument_name)

    {input_value, arguments} = Map.pop!(arguments, argument_name)

    case load_function.(input_value) do
      nil ->
        :not_found

      entities when is_list(entities) ->
        # TODO: Can we assume the result is a list of entities
        #  based on the output of the load function?
        # We could also check the input type,
        #  but the saver solution might be to to add a `is_list` option.

        entities = Enum.reject(entities, &is_nil/1)

        if is_list(input_value) and length(entities) != length(input_value) do
          :not_found
        else
          Map.put(arguments, push_to_key, entities)
        end

      value ->
        Map.put(arguments, push_to_key, value)
    end
  end

  def load_entities(arguments, _argument_identifier, _opts) do
    arguments
  end
end
