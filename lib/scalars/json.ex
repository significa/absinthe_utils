defmodule AbsintheUtils.Scalars.JSON do
  @moduledoc """
  The JSON scalar type allows arbitrary JSON values to be passed in and out.
  Requires `{ :jason, "~> 1.1" }` package: https://github.com/michalmuskala/jason

  Based in the recipe from Absinthe
  https://github.com/absinthe-graphql/absinthe/wiki/Scalar-Recipes#json-using-jason

  Note that even if you use `non_null(:json)` a string of null value (`"null"`) is still accepted.
  """
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description("""
    The `JSON` scalar type represents arbitrary JSON string data, represented as UTF-8
    character sequences. The JSON type is most often used to represent a free-form
    human-readable json string.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_), do: :error

  defp encode(value), do: value
end
