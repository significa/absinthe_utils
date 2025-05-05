defmodule AbsintheUtils.Scalars.StrictNaiveDateTime do
  @description """
  The `StrictNaiveDateTime` scalar type represents a naive date and time without
  timezone.
  The output is an ISO8601 formatted string.
  The input must be a naive datetime, without timezone offset.

  Valid examples:
  - 2020-01-01T00:00:00
  - 2020-01-01 00:00:00

  Invalid examples:
  - 2020-01-01T00:00:00+00:00
  - 2020-01-01T00:00:00+01:00
  - 2020-01-01T00:00:00Z
  - 2020-01-01 00:00:00Z
  """

  @moduledoc """
  #{@description}

  **Usage:**

  Import the type in your schema `import_types(AbsintheUtils.Scalars.StrictNaiveDateTime)` and you will be able
  to use the `:strict_naive_datetime` type.

  **Acknowledgements:**

  Based on the type `naive_datetime` from `Absinthe.Type.Custom`.
  """

  use Absinthe.Schema.Notation

  scalar :strict_naive_datetime, name: "StrictNaiveDateTime" do
    description(@description)

    parse(&parse_naive_datetime/1)

    serialize(fn value ->
      case value do
        %NaiveDateTime{} -> NaiveDateTime.to_iso8601(value)
        _ -> raise Absinthe.SerializationError, "Invalid naive datetime value"
      end
    end)
  end

  @spec parse_naive_datetime(Absinthe.Blueprint.Input.String.t()) ::
          {:ok, NaiveDateTime.t()} | :error
  @spec parse_naive_datetime(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_naive_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case DateTime.from_iso8601(value) do
      {:error, :missing_offset} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive_datetime} -> {:ok, naive_datetime}
          _error -> {:error, "Invalid ISO8601 datetime"}
        end

      {:ok, _datetime, offset} when not is_nil(offset) ->
        {
          :error,
          "Invalid ISO8601 datetime without timezone offset. Received an offset of #{offset}, expected no offset. " <>
            "Example: 2020-01-01T00:00:00 instead of 2020-01-01T00:00:00Z. " <>
            "For more information refer to the GraphQL description of this field type."
        }

      _ ->
        {:error, "Invalid ISO8601 datetime without timezone offset"}
    end
  end

  defp parse_naive_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_naive_datetime(_) do
    :error
  end
end
