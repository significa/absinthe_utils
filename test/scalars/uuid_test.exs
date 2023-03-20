defmodule AbsintheUtilsTest.Scalars.UUIDTest do
  use ExUnit.Case, async: true

  @sample_uuid "857b262d-a8c7-48b5-9ee3-06d735136693"

  defmodule TestSchema do
    use Absinthe.Schema

    import_types(AbsintheUtils.Scalars.EctoUUID)

  @sample_uuid "857b262d-a8c7-48b5-9ee3-06d735136693"

    query do
      field :query_with_uuid_argument, :string do
        arg(:uuid, :uuid)

        resolve(fn _, params, _ ->
          {:ok, params.uuid}
        end)
      end

      field :query_returns_uuid, :uuid do
        resolve(fn _, _, _ ->
          {:ok, @sample_uuid}
        end)
      end

      field :query_returns_invalid_uuid, :uuid do
        resolve(fn _, _, _ ->
          {:ok, "invalid_uuid"}
        end)
      end
    end
  end

  describe "input" do
    test "valid uuid" do
      assert {:ok,
              %{
                data: %{
                  "queryWithUUIDArgument" => @sample_uuid
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $uuid: UUID
                   ) {
                    queryWithUUIDArgument(
                      uuid: $uuid
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "uuid" => @sample_uuid
                 }
               )
    end

    test "invalid uuid" do
      assert {:ok,
              %{
                errors: [
                  %{
                    message: "Argument \"uuid\" has invalid value $uuid."
                  }
                ]
              }} =
               Absinthe.run(
                 """
                   query (
                     $uuid: UUID
                   ) {
                    queryWithUUIDArgument(
                      uuid: $uuid
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "uuid" => "invalid_uuid"
                 }
               )
    end
  end

  describe "output" do
    test "valid uuid" do
      assert {:ok,
              %{
                data: %{
                  "queryReturnsUUID" => @sample_uuid
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                    queryReturnsUUID
                   }
                 """,
                 TestSchema
               )
    end

    test "invalid uuid" do
      assert_raise Absinthe.SerializationError, fn ->
        Absinthe.run(
          """
            query {
             queryReturnsInvalidUUID
            }
          """,
          TestSchema
        )
      end
    end
  end
end
