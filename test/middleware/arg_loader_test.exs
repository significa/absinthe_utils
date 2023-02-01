defmodule AbsintheUtilsTest.Middleware.ArgLoaderTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Middleware.ArgLoader

  defmodule SampleRepository do
    @moduledoc """
    This is a demo api used as a "mock" called by resolvers.
    This test case would probably be better tested with real mocks on the resolvers
     so we could assert calls and have more control of the flow.
     But for the ease of development this was chosen for now.
    """
    @users [
      %{id: "1", name: "Ally"},
      %{id: "2", name: "Bob"}
    ]

    def get_by_id(enumerable, id) do
      {
        :ok,
        Enum.find(
          enumerable,
          fn item -> item.id == id end
        )
      }
    end

    def filter_by_ids(enumerable, ids) do
      {
        :ok,
        Enum.filter(
          enumerable,
          fn item -> item.id in ids end
        )
      }
    end

    def get_user(id), do: get_by_id(@users, id)
    def get_users(ids), do: filter_by_ids(@users, ids)
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
              load_function: &SampleRepository.get_user/1
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
              load_function: &SampleRepository.get_users/1
            ]
          }
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :users)}
        end)
      end

      field :two_users, non_null(list_of(:user)) do
        arg(:user1_id, :id)
        arg(:user2_id, :id)

        middleware(
          ArgLoader,
          %{
            user1_id: [
              new_name: :user1,
              load_function: &SampleRepository.get_user/1
            ],
            user2_id: [
              new_name: :user2,
              load_function: &SampleRepository.get_user/1
            ]
          }
        )

        resolve(fn _, params, _ ->
          {
            :ok,
            [
              Map.get(params, :user1),
              Map.get(params, :user2)
            ]
          }
        end)
      end
    end
  end

  describe "loading one argument" do
    test "success" do
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

    test "optional not passed" do
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

    test "not found" do
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

  describe "loading one array argument" do
    test "success" do
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

  describe "loading two arguments" do
    test "success" do
      assert {
               :ok,
               %{
                 data: %{
                   "twoUsers" => [
                     %{"id" => "2", "name" => "Bob"},
                     %{"id" => "1", "name" => "Ally"}
                   ]
                 }
               }
             } ===
               Absinthe.run(
                 """
                   query (
                     $user1Id: ID!
                     $user2Id: ID!
                   ) {
                    twoUsers (
                      user1Id: $user1Id
                      user2Id: $user2Id
                     ) {
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "user1Id" => "2",
                   "user2Id" => "1"
                 }
               )
    end

    test "one not provided" do
      assert {
               :ok,
               %{
                 data: %{
                   "twoUsers" => [
                     nil,
                     %{"id" => "2", "name" => "Bob"}
                   ]
                 }
               }
             } ===
               Absinthe.run(
                 """
                   query (
                     $user2Id: ID!
                   ) {
                    twoUsers (
                      user2Id: $user2Id
                     ) {
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "user2Id" => "2"
                 }
               )
    end

    test "none provided" do
      assert {
               :ok,
               %{
                 data: %{
                   "twoUsers" => [nil, nil]
                 }
               }
             } ===
               Absinthe.run(
                 """
                   query {
                    twoUsers {
                      id
                      name
                     }
                   }
                 """,
                 TestSchema
               )
    end

    test "error one not found" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{code: "NOT_FOUND"},
                     message:
                       "The entity(ies) provided in the following arg(s), could not be found: user2_id"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query (
                     $user1Id: ID!
                     $user2Id: ID!
                   ) {
                    twoUsers (
                      user1Id: $user1Id
                      user2Id: $user2Id
                     ) {
                      id
                      name
                     }
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "user1Id" => "1",
                   "user2Id" => "invalid"
                 }
               )
    end
  end
end
