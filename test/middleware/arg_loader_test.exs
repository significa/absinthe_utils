defmodule AbsintheUtilsTest.Middleware.ArgLoaderTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Middleware.ArgLoader

  defmodule SampleUserApi do
    @users [
      %{id: "1", name: "Ally"},
      %{id: "2", name: "Bob"}
    ]

    def get_user(id) do
      {
        :ok,
        Enum.find(
          @users,
          fn user -> user.id == id end
        )
      }
    end

    def get_users(ids) do
      {
        :ok,
        Enum.filter(
          @users,
          fn user -> user.id in ids end
        )
      }
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    object :user do
      field(:id, :id)
      field(:name, :string)
    end

    query do
      field :user, :user do
        arg(:id, :id)

        middleware(
          ArgLoader,
          %{
            id: [
              new_name: :user,
              load_function: &SampleUserApi.get_user/1
            ]
          }
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :user)}
        end)
      end

      field :users, non_null(list_of(:user)) do
        arg(:ids, non_null(list_of(:id)))

        middleware(
          ArgLoader,
          %{
            ids: [
              new_name: :users,
              load_function: &SampleUserApi.get_users/1
            ]
          }
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :users)}
        end)
      end
    end
  end

  describe "argument" do
    test "loading user by id" do
      assert {:ok,
              %{
                data: %{
                  "user" => %{
                    "id" => "1",
                    "name" => "Ally"
                  }
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $id: ID!
                   ) {
                    user(
                      id: $id
                     ){
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "id" => "1"
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{
                  "user" => nil
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                    user {
                      id
                      name
                     }
                   }
                 """,
                 TestSchema
               )
    end

    test "user not found" do
      assert {:ok,
              %{
                errors: [
                  %{
                    extensions: %{code: "NOT_FOUND"},
                    message:
                      "The entity(ies) provided in the following arg(s), could not be found: id"
                  }
                ]
              }} =
               Absinthe.run(
                 """
                   query (
                     $id: ID!
                   ) {
                   user(
                     id: $id
                     ){
                     id
                     name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "id" => "invalid"
                 }
               )
    end
  end

  describe "list argument" do
    test "loading users by ids" do
      assert {:ok,
              %{
                data: %{
                  "users" => [
                    %{"id" => "1", "name" => "Ally"},
                    %{"id" => "2", "name" => "Bob"}
                  ]
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $ids: [ID]!
                   ) {
                    users(
                      ids: $ids
                     ){
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "ids" => ["1", "2"]
                 }
               )
    end

    test "empty list" do
      assert {
               :ok,
               %{
                 data: %{
                   "users" => []
                 }
               }
             } ===
               Absinthe.run(
                 """
                   query (
                     $ids: [ID]!
                   ) {
                    users(
                      ids: $ids
                     ){
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "ids" => []
                 }
               )
    end

    test "not found" do
      assert {:ok,
              %{
                errors: [
                  %{
                    extensions: %{code: "NOT_FOUND"},
                    message:
                      "The entity(ies) provided in the following arg(s), could not be found: ids"
                  }
                ]
              }} =
               Absinthe.run(
                 """
                   query (
                     $ids: [ID]!
                   ) {
                    users(
                      ids: $ids
                     ){
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "ids" => ["1", "invalid", "2"]
                 }
               )
    end
  end
end
