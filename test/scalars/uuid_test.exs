defmodule AbsintheUtilsTest.Scalars.UUIDTest do
  use ExUnit.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    import_types(AbsintheUtils.Scalars.EctoUUID)

    query do
      field :query_with_uuid_argument, :boolean do
        arg(:uuid, :uuid)

        resolve(fn _, _, _ ->
          {:ok, true}
        end)
      end

      field :query_returns_uuid, :uuid do
        resolve(fn _, _, _ ->
          {:ok, Ecto.UUID.generate()}
        end)
      end

      field :query_does_not_return_uuid, :uuid do
        resolve(fn _, _, _ ->
          {:ok, "string"}
        end)
      end
    end
  end

  describe "uuid decode" do
    test "valid uuid" do
      assert {:ok,
              %{
                data: %{
                  "queryWithUUIDArgument" => true
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
                   "uuid" => "68333b2e-51f8-4898-affb-2608949bf71a"
                 }
               )
    end

    test "invalid uuid" do
      assert {:ok,
      %{
        errors: [%{
          message: "Argument \"uuid\" has invalid value $uuid."
        }]
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

  describe "uuid endecode" do
    test "valid uuid" do
      assert {:ok,
              %{
                data: %{
                  "queryReturnsUUID" => uuid
                }
              }} =
               Absinthe.run(
                 """
                   query {
                    queryReturnsUUID
                   }
                 """,
                 TestSchema
               )

      assert Ecto.UUID.cast!(uuid)
    end

    test "invalid uuid" do
      assert {:ok,
              %{
                data: %{
                  "queryDoesNotReturnUUID" => uuid
                }
              }} =
               Absinthe.run(
                 """
                   query {
                    queryDoesNotReturnUUID
                   }
                 """,
                 TestSchema
               )

      assert_raise Ecto.CastError, fn ->
        Ecto.UUID.cast!(uuid)
      end
    end
  end
end
