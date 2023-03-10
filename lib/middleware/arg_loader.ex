defmodule AbsintheUtils.Middleware.ArgLoader do
  @moduledoc """
  Absinthe middleware for loading entities in `field` arguments.

  This middleware should be defined before `resolve`. It will manipulate the arguments
  before they are passed to the resolver function.

  As configuration it accepts a map of original argument names to a keyword list, containing:

  - `load_function`: the function used to load the argument into an entity.
    As an input accepts one single argument: the input received in the resolution.
    It returns a tuple of `{:ok, nil}`  `{:ok, nil}` o
  - `new_name`: the new name to push the loaded entity into.
    (optional, defaults to the original argument name).


  ## Example

  ```
  query do
    field :user, :user do
      arg(:id, :id)

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

  """

  @behaviour Absinthe.Middleware

  alias AbsintheUtilsTest.Helpers.Errors

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

      values when is_list(values) ->
        # FIXME: we should not assume a list based on the output of the load function
        # WE could also check the input type, but it would be better to replace it with a configuration flag
        if length(values) != length(input_value) do
          :not_found
        else
          Map.put(arguments, push_to_key, values)
        end

      value ->
        Map.put(arguments, push_to_key, value)
    end
  end

  def load_entities(arguments, _argument_identifier, _opts) do
    arguments
  end
end
