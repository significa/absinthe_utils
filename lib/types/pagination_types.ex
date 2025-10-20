defmodule AbsintheUtils.Types.PaginationTypes do
  @moduledoc """
  Absinthe types for pagination parameters and details.

  Usage:
  1. Import the required type in your Absinthe schema.
     ```
     import_types(AbsintheUtils.Types.PaginationTypes)
     ```

  2. Use the `:pagination_params` input object and `:pagination_details` object in your queries or mutations.
     ```
     input do
       field :pagination, :pagination_params
     end
     ```

  """

  use Absinthe.Schema.Notation

  input_object :pagination_params do
    field(:page, non_null(:integer))
    field(:page_size, non_null(:integer))
  end

  object :pagination_details do
    field(:page_size, non_null(:integer))
    field(:page_number, non_null(:integer))
    field(:total_entries, non_null(:integer))
    field(:total_pages, non_null(:integer))
  end

  enum :sorting_direction do
    value(:asc)
    value(:desc)
  end
end
