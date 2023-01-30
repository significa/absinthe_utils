defmodule AbsintheUtils.Middleware.ArgLoader do
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
        "The entities provided in the following ids, could not be found: " <>
          Enum.join(not_found_arguments, ", "),
        "NOT_FOUND"
      )
    end
  end

  def load_entities(arguments, argument_name, opts)
      when is_map_key(arguments, argument_name) do
    load_function = Keyword.fetch!(opts, :load_function)
    push_to_key = Keyword.get(opts, :new_name, argument_name)

    {entity_key, arguments} = Map.pop!(arguments, argument_name)

    # TODO: Clean this up, too complex and hard to read
    case load_function.(entity_key) do
      {:ok, nil} ->
        :not_found

      {:ok, value} ->
        Map.put(arguments, push_to_key, value)
    end
  end

  def load_entities(arguments, _argument_identifier, _opts) do
    arguments
  end
end
