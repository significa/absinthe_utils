defmodule AbsintheUtilsTest.Scalars.JSONTest do
  use ExUnit.Case, async: true

  @sample_data %{
    "users" => [
      %{
        "id" => 1234,
        "name" => "Sample user name",
        "is_active" => true,
        "pet" => nil
      }
    ]
  }

  defmodule TestSchema do
    use Absinthe.Schema

    import_types(AbsintheUtils.Scalars.JSON)

    enum :test_result do
      value(:not_in_params)
      value(:is_null)
      value(:not_null)
    end

    object :sample_json_fields do
      field(:null_value, :json)
      field(:empty_array, non_null(:json))
      field(:empty_object, non_null(:json))
      field(:sample_object, non_null(:json))
    end

    query do
      field :sample_json_arg, :test_result do
        arg(:data, non_null(:json))

        resolve(fn _, params, _ ->
          {
            :ok,
            cond do
              not Map.has_key?(params, :data) ->
                :not_in_params

              Map.fetch!(params, :data) == nil ->
                :is_null

              true ->
                :not_null
            end
          }
        end)
      end

      field :sample_json_return, :sample_json_fields do
        resolve(fn _, _params, _ ->
          {
            :ok,
            %{
              null_field: nil,
              empty_array: [],
              empty_object: %{},
              sample_object: %{
                "users" => [
                  %{
                    "id" => 1234,
                    "name" => "Sample user name",
                    "is_active" => true,
                    "pet" => nil
                  }
                ]
              }
            }
          }
        end)
      end
    end
  end

  describe "input" do
    test "valid empty object" do
      assert {:ok,
              %{
                data: %{
                  "sampleJsonArg" => "NOT_NULL"
                }
              }} ==
               Absinthe.run(
                 """
                  query (
                    $data: JSON!
                  ) {
                    sampleJsonArg(
                      data: $data
                    )
                  }
                 """,
                 TestSchema,
                 variables: %{
                   "data" => "{}"
                 }
               )
    end

    test "valid empty array" do
      assert {:ok,
              %{
                data: %{
                  "sampleJsonArg" => "NOT_NULL"
                }
              }} ==
               Absinthe.run(
                 """
                  query (
                    $data: JSON!
                  ) {
                    sampleJsonArg(
                      data: $data
                    )
                  }
                 """,
                 TestSchema,
                 variables: %{
                   "data" => "[]"
                 }
               )
    end

    test "valid null" do
      # TODO: we should be receiving a null.
      #  The value is being removed from `params`.

      assert {:ok,
              %{
                data: %{
                  "sampleJsonArg" => "NOT_IN_PARAMS"
                }
              }} ==
               Absinthe.run(
                 """
                  query (
                    $data: JSON!
                  ) {
                    sampleJsonArg(
                      data: $data
                    )
                  }
                 """,
                 TestSchema,
                 variables: %{
                   "data" => "null"
                 }
               )
    end

    test "valid sample nested data" do
      assert {:ok,
              %{
                data: %{
                  "sampleJsonArg" => "NOT_NULL"
                }
              }} ==
               Absinthe.run(
                 """
                  query (
                    $data: JSON!
                  ) {
                    sampleJsonArg(
                      data: $data
                    )
                  }
                 """,
                 TestSchema,
                 variables: %{
                   "data" =>
                     @sample_data
                     |> Jason.encode!()
                 }
               )
    end

    test "invalid" do
      assert {:ok,
              %{
                errors: [
                  %{
                    message: "Argument \"data\" has invalid value $data."
                  }
                ]
              }} =
               Absinthe.run(
                 """
                  query (
                    $data: JSON!
                  ) {
                    sampleJsonArg(
                      data: $data
                    )
                  }
                 """,
                 TestSchema,
                 variables: %{
                   "data" => "invalid JSON"
                 }
               )
    end
  end

  test "output" do
    assert {
             :ok,
             %{
               data: %{
                 "sampleJsonReturn" => %{
                   "empty_array" => [],
                   "empty_object" => %{},
                   "null_value" => nil,
                   "sample_object" => sample_object
                 }
               }
             }
           } =
             Absinthe.run(
               """
                query {
                  sampleJsonReturn {
                    null_value
                    empty_array
                    empty_object
                    sample_object
                  }
                }
               """,
               TestSchema
             )

    assert @sample_data == sample_object
  end
end
