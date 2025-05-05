defmodule AbsintheUtilsTest.Scalars.StrictNaiveDateTimeTest do
  use ExUnit.Case, async: true

  @sample_naive_datetime_string "2020-01-01T00:00:00"

  defmodule TestSchema do
    use Absinthe.Schema

    import_types(AbsintheUtils.Scalars.StrictNaiveDateTime)

    @sample_naive_datetime ~N[2020-01-01 00:00:00]

    query do
      field :query_with_naive_date_time_argument, :strict_naive_datetime do
        arg(:naive_date_time, :strict_naive_datetime)

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :naive_date_time)}
        end)
      end

      field :query_returning_naive_date_time, :strict_naive_datetime do
        resolve(fn _, _, _ ->
          {:ok, @sample_naive_datetime}
        end)
      end

      field :query_returning_invalid_naive_date_time, :strict_naive_datetime do
        resolve(fn _, _, _ ->
          {:ok, "invalid_strict_naive_datetime"}
        end)
      end
    end
  end

  describe "input" do
    @query """
      query (
        $naiveDateTime: StrictNaiveDateTime
      ) {
        queryWithNaiveDateTimeArgument (
         naiveDateTime: $naiveDateTime
        )
      }
    """

    test "valid naive datetime" do
      assert {:ok,
              %{
                data: %{
                  "queryWithNaiveDateTimeArgument" => @sample_naive_datetime_string
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "naiveDateTime" => @sample_naive_datetime_string
                 }
               )
    end

    test "invalid naive datetime" do
      assert {:ok,
              %{
                errors: [
                  %{
                    message:
                      "Argument \"naiveDateTime\" has invalid value $naiveDateTime.\nInvalid ISO8601 datetime without timezone offset"
                  }
                ]
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "naiveDateTime" => "invalid_naive_datetime"
                 }
               )
    end

    test "invalid passing a datetime with offset" do
      assert {:ok,
              %{
                errors: [
                  %{
                    message:
                      "Argument \"naiveDateTime\" has invalid value $naiveDateTime.\nInvalid ISO8601" <>
                        " datetime without timezone offset. Received an offset of 0, expected no offset." <>
                        " Example: 2020-01-01T00:00:00 instead of 2020-01-01T00:00:00Z." <>
                        " For more information refer to the GraphQL description of this field type."
                  }
                ]
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "naiveDateTime" => "2020-01-01T00:00:00+00:00"
                 }
               )
    end
  end

  describe "output" do
    test "valid naive datetime" do
      assert {:ok,
              %{
                data: %{
                  "queryReturningNaiveDateTime" => @sample_naive_datetime_string
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryReturningNaiveDateTime
                   }
                 """,
                 TestSchema
               )
    end

    test "invalid naive datetime" do
      assert_raise Absinthe.SerializationError, fn ->
        Absinthe.run(
          """
            query {
              queryReturningInvalidNaiveDateTime
            }
          """,
          TestSchema
        )
      end
    end
  end
end
