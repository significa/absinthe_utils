is_ecto_loaded =
  try do
    Code.ensure_compiled!(Ecto.UUID)
    true
  rescue
    _ ->
      false
  end

if is_ecto_loaded do
  defmodule AbsintheUtils.Scalars.UUID do
    @moduledoc """
    The UUID scalar type allows UUID compliant strings to be passed in and out.
    Requires `{ :ecto, ">= 0.0.0" }` package: https://github.com/elixir-ecto/ecto

    Based in the
    [recipes on Absinthe's wiki](https://github.com/absinthe-graphql/absinthe/wiki/Scalar-Recipes)

    **Usage:**

    Import the type in your schema `import_types(AbsintheUtils.Scalars.JSON)` and you will be able
    to use the `:json` type.
    """
    use Absinthe.Schema.Notation

    alias Ecto.UUID

    scalar :uuid, name: "UUID" do
      description("""
      The `UUID` scalar type represents UUID compliant string data, represented as UTF-8
      character sequences. The UUID type is most often used to represent unique
      machine-readable ID strings.
      """)

      serialize(&encode/1)
      parse(&decode/1)
    end

    @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
    @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
    defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
      UUID.cast(value)
    end

    defp decode(%Absinthe.Blueprint.Input.Null{}) do
      {:ok, nil}
    end

    defp decode(_), do: :error

    defp encode(value) do
      case UUID.cast(value) do
        :error ->
          raise Absinthe.SerializationError,
                "Could not serialize term #{inspect(value)} as type UUID."

        {:ok, uuid} ->
          uuid
      end
    end
  end
end
