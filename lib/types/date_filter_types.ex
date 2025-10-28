defmodule AbsintheUtils.Types.DateFilterTypes do
  @moduledoc """
  Absinthe input objects for date and datetime filtering.

  Usage:

  1. Import the required type in your Absinthe schema.
     ```
     import_types(AbsintheUtils.Scalars.StrictNaiveDateTime)
     import_types(AbsintheUtils.Types.DateFilterTypes)
     ```

  2. Use the `:date_filter` and `:datetime_filter` input objects in your queries or mutations.
     Example:
     ```
     input do
       field :created_at, :datetime_filter
     end
     ```
  """

  use Absinthe.Schema.Notation

  input_object :date_filter do
    field(:gte, :date)
    field(:lte, :date)
  end

  input_object :datetime_filter do
    field(:gte, :datetime)
    field(:lte, :datetime)
  end

  input_object :strict_naive_datetime_filter do
    field(:gte, :strict_naive_datetime)
    field(:lte, :strict_naive_datetime)
  end
end
