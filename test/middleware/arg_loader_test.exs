defmodule AbsintheUtilsTest.Middleware.ArgLoaderTest do
  use ExUnit.Case, async: true

  # use Absinthe.Schema

  defmodule SampleRepository do
    @moduledoc """
    This is a demo api used as a "mock" called by resolve_paramss.
    This test case would probably be better tested with real mocks on the resolve_paramss
     so we could assert calls and have more control of the flow.
     But for the ease of development this was chosen for now.
    """
    @user_id_to_user %{
      "1" => %{id: "1", name: "Ally"},
      "2" => %{id: "2", name: "Bob"}
    }

    def get_user(id) do
      Map.get(@user_id_to_user, id)
    end

    @doc """
    Demo multi-user getter that returns an user for each id provided.
    If not found, `nil` is returned in its place.
    """
    def get_optional_users(nil), do: []

    def get_optional_users(ids) do
      ids
      |> Enum.map(&get_user/1)
    end

    @doc """
    Demo multi-user getter that returns an user for each id provided.
    If not found, it will not be returned.
    """
    def get_users(ids) do
      ids
      |> get_optional_users()
      |> Enum.reject(&is_nil/1)
    end

    @doc """
    Demo multi-user getter that returns a list of unique users (removes duplicates from the input).
    This is usually the case when loading users from database.
    """
    def get_unique_users(nil), do: []

    def get_unique_users(ids) do
      ids
      |> Enum.uniq()
      |> get_users()
    end
  end

  defmodule TestSchema do
    @moduledoc false

    use Absinthe.Schema

    alias AbsintheUtils.Middleware.ArgLoader

    object :user do
      field(:id, non_null(:id))
      field(:name, non_null(:string))
    end

    object :single_entity do
      field(:user, non_null(:user))
    end

    object :two_entities do
      field(:user1, non_null(:user))
      field(:user2, non_null(:user))
    end

    object :entity_list do
      field(:users, non_null(list_of(:user)))
    end

    def resolve_params(_, params, _) do
      {:ok, params}
    end

    query do
      field :optional_entity, :single_entity do
        arg(:id, :id)

        middleware(
          ArgLoader,
          %{
            id: [
              new_name: :user,
              load_function: &SampleRepository.get_user/1,
              nil_is_not_found: false
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :required_entity, :single_entity do
        arg(:id, :id)

        middleware(
          ArgLoader,
          %{
            id: [
              new_name: :user,
              load_function: &SampleRepository.get_user/1,
              nil_is_not_found: true
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :required_entity_with_default, :single_entity do
        arg(:id, :id)

        middleware(
          ArgLoader,
          %{
            id: [
              new_name: :user,
              load_function: &SampleRepository.get_user/1
              # Using default nil_is_not_found
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :optional_entities, :entity_list do
        arg(:ids, list_of(:id))

        middleware(
          ArgLoader,
          %{
            ids: [
              new_name: :users,
              load_function: &SampleRepository.get_optional_users/1,
              nil_is_not_found: false
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :required_entities, :entity_list do
        arg(:ids, list_of(:id))

        middleware(
          ArgLoader,
          %{
            ids: [
              new_name: :users,
              load_function: &SampleRepository.get_users/1,
              nil_is_not_found: true
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :required_entities_with_default, :entity_list do
        arg(:ids, list_of(:id))

        middleware(
          ArgLoader,
          %{
            ids: [
              new_name: :users,
              load_function: &SampleRepository.get_users/1
              # Using default nil_is_not_found
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      field :unique_entities, :entity_list do
        arg(:ids, list_of(:id))

        middleware(
          ArgLoader,
          %{
            ids: [
              new_name: :users,
              load_function: &SampleRepository.get_unique_users/1
            ]
          }
        )

        resolve(&resolve_params/3)
      end

      # field :users, non_null(list_of(:user)) do
      #   arg(:ids, non_null(list_of(:id)))

      #   middleware(
      #     ArgLoader,
      #     %{
      #       ids: [
      #         new_name: :users,
      #         load_function: &SampleRepository.get_users/1
      #       ]
      #     }
      #   )

      #   resolve(&resolve_params/3)
      # end

      # field :unique_users_order_preserved, non_null(list_of(:user)) do
      #   arg(:ids, non_null(list_of(:id)))

      #   middleware(
      #     ArgLoader,
      #     %{
      #       ids: [
      #         new_name: :users,
      #         load_function: fn ids ->
      #           ids
      #           |> SampleRepository.get_users()
      #           |> AbsintheUtils.Helpers.Sorting.sort_alike(ids, & &1.id)
      #         end
      #       ]
      #     }
      #   )

      #   resolve(&resolve_params/3)
      # end

      # field :two_entities, non_null(list_of(:user)) do
      #   arg(:user1_id, :id)
      #   arg(:user2_id, :id)

      #   middleware(
      #     ArgLoader,
      #     %{
      #       user1_id: [
      #         new_name: :user1,
      #         load_function: &SampleRepository.get_user/1
      #       ],
      #       user2_id: [
      #         new_name: :user2,
      #         load_function: &SampleRepository.get_user/1
      #       ]
      #     }
      #   )

      #   resolve(&resolve_params/3)
      # end
    end
  end

  describe "optional entity" do
    @query """
      query ($id: ID) {
        optionalEntity(
          id: $id
        ) {
          user {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "optionalEntity" => %{
                    "user" => %{
                      "id" => "1",
                      "name" => "Ally"
                    }
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "1"
                 }
               )
    end

    test "nil argument" do
      assert {:ok,
              %{
                data: %{"optionalEntity" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"optionalEntity" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
               )
    end

    test "not found" do
      assert {:ok,
              %{
                data: %{"optionalEntity" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "unknown"
                 }
               )
    end
  end

  describe "required entity" do
    @query """
      query ($id: ID) {
        requiredEntity(
          id: $id
        ) {
          user {
            id
            name
          }
        }
      }
    """
    test "success" do
      assert {:ok,
              %{
                data: %{
                  "requiredEntity" => %{
                    "user" => %{
                      "id" => "1",
                      "name" => "Ally"
                    }
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "1"
                 }
               )
    end

    test "nil argument" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"requiredEntity" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
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
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "unknown"
                 }
               )
    end
  end

  describe "required entity - using default" do
    @query """
      query ($id: ID) {
        requiredEntityWithDefault(
          id: $id
        ) {
          user {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "requiredEntityWithDefault" => %{
                    "user" => %{
                      "id" => "1",
                      "name" => "Ally"
                    }
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "1"
                 }
               )
    end

    test "nil argument" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => nil
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
                      "The entity(ies) provided in the following arg(s), could not be found: id"
                  }
                ]
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "id" => "unknown"
                 }
               )
    end
  end

  describe "optional entities" do
    @query """
      query ($ids: [ID]) {
        optionalEntities(
          ids: $ids
        ) {
          users {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "optionalEntities" => %{
                    "users" => [
                      %{
                        "id" => "1",
                        "name" => "Ally"
                      }
                    ]
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["1"]
                 }
               )
    end

    test "nil input list" do
      assert {:ok,
              %{
                data: %{"optionalEntities" => %{"users" => []}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"optionalEntities" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
               )
    end

    test "nil element id" do
      assert {:ok,
              %{
                data: %{"optionalEntities" => %{"users" => [nil]}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => [nil]
                 }
               )
    end

    test "not found" do
      assert {:ok,
              %{
                data: %{"optionalEntities" => %{"users" => [nil]}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown"]
                 }
               )
    end

    test "mixed- valid and not found" do
      assert {:ok,
              %{
                data: %{
                  "optionalEntities" => %{"users" => [nil, %{"id" => "1", "name" => "Ally"}]}
                }
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown", "1"]
                 }
               )
    end
  end

  describe "required entities" do
    @query """
      query ($ids: [ID]) {
        requiredEntities(
          ids: $ids
        ) {
          users {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "requiredEntities" => %{
                    "users" => [
                      %{
                        "id" => "1",
                        "name" => "Ally"
                      }
                    ]
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["1"]
                 }
               )
    end

    test "nil input list" do
      assert {:ok,
              %{
                data: %{"requiredEntities" => %{"users" => []}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"requiredEntities" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
               )
    end

    test "nil element id" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => [nil]
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown"]
                 }
               )
    end

    test "mixed- valid and not found" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown", "1"]
                 }
               )
    end
  end

  describe "required entities - using default" do
    @query """
      query ($ids: [ID]) {
        requiredEntitiesWithDefault(
          ids: $ids
        ) {
          users {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "requiredEntitiesWithDefault" => %{
                    "users" => [
                      %{
                        "id" => "1",
                        "name" => "Ally"
                      }
                    ]
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["1"]
                 }
               )
    end

    test "nil input list" do
      assert {:ok,
              %{
                data: %{"requiredEntitiesWithDefault" => %{"users" => []}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"requiredEntitiesWithDefault" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
               )
    end

    test "nil element id" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => [nil]
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown"]
                 }
               )
    end

    test "mixed - valid and not found" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown", "1"]
                 }
               )
    end
  end

  describe "unique entities" do
    @query """
      query ($ids: [ID]) {
        uniqueEntities(
          ids: $ids
        ) {
          users {
            id
            name
          }
        }
      }
    """

    test "success" do
      assert {:ok,
              %{
                data: %{
                  "uniqueEntities" => %{
                    "users" => [
                      %{
                        "id" => "1",
                        "name" => "Ally"
                      }
                    ]
                  }
                }
              }} ===
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["1"]
                 }
               )
    end

    test "nil input list" do
      assert {:ok,
              %{
                data: %{"uniqueEntities" => %{"users" => []}}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => nil
                 }
               )
    end

    test "argument not passed" do
      assert {:ok,
              %{
                data: %{"uniqueEntities" => nil}
              }} =
               Absinthe.run(
                 @query,
                 TestSchema,
                 variables: %{}
               )
    end

    test "nil element id" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => [nil]
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown"]
                 }
               )
    end

    test "mixed- valid and not found" do
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
                 @query,
                 TestSchema,
                 variables: %{
                   "ids" => ["unknown", "1"]
                 }
               )
    end
  end
end

# ####

# describe "loading one argument" do
#   test "success" do
#     assert {:ok,
#             %{
#               data: %{
#                 "user" => %{
#                   "id" => "1",
#                   "name" => "Ally"
#                 }
#               }
#             }} ===
#              Absinthe.run(
#                """
#                  query (
#                    $id: ID!
#                  ) {
#                   user(
#                     id: $id
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "id" => "1"
#                }
#              )
#   end

#   test "optional not passed" do
#     assert {:ok,
#             %{
#               data: %{
#                 "user" => nil
#               }
#             }} ===
#              Absinthe.run(
#                """
#                  query {
#                   user {
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema
#              )
#   end

#   test "not found" do
#     assert {:ok,
#             %{
#               errors: [
#                 %{
#                   extensions: %{code: "NOT_FOUND"},
#                   message:
#                     "The entity(ies) provided in the following arg(s), could not be found: id"
#                 }
#               ]
#             }} =
#              Absinthe.run(
#                """
#                  query (
#                    $id: ID!
#                  ) {
#                  user(
#                    id: $id
#                    ){
#                    id
#                    name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "id" => "unknown"
#                }
#              )
#   end
# end

# describe "loading one array argument" do
#   test "success" do
#     assert {:ok,
#             %{
#               data: %{
#                 "users" => [
#                   %{"id" => "1", "name" => "Ally"},
#                   %{"id" => "2", "name" => "Bob"}
#                 ]
#               }
#             }} ===
#              Absinthe.run(
#                """
#                  query (
#                    $ids: [ID]!
#                  ) {
#                   users(
#                     ids: $ids
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "ids" => ["1", "2"]
#                }
#              )
#   end

#   test "empty list" do
#     assert {
#              :ok,
#              %{
#                data: %{
#                  "users" => []
#                }
#              }
#            } ===
#              Absinthe.run(
#                """
#                  query (
#                    $ids: [ID]!
#                  ) {
#                   users(
#                     ids: $ids
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "ids" => []
#                }
#              )
#   end

#   test "not found - unknown id" do
#     assert {:ok,
#             %{
#               errors: [
#                 %{
#                   extensions: %{code: "NOT_FOUND"},
#                   message:
#                     "The entity(ies) provided in the following arg(s), could not be found: ids"
#                 }
#               ]
#             }} =
#              Absinthe.run(
#                """
#                  query (
#                    $ids: [ID]!
#                  ) {
#                   users(
#                     ids: $ids
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "ids" => ["1", "unknown", "2"]
#                }
#              )
#   end

#   test "not found - duplicate ids" do
#     assert {:ok,
#             %{
#               errors: [
#                 %{
#                   extensions: %{code: "NOT_FOUND"},
#                   message:
#                     "The entity(ies) provided in the following arg(s), could not be found: ids"
#                 }
#               ]
#             }} =
#              Absinthe.run(
#                """
#                  query (
#                    $ids: [ID]!
#                  ) {
#                   users(
#                     ids: $ids
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "ids" => ["1", "1", "2"]
#                }
#              )
#   end

#   test "not found when using Sorting.sort_alike" do
#     assert {:ok,
#             %{
#               errors: [
#                 %{
#                   extensions: %{code: "NOT_FOUND"},
#                   message:
#                     "The entity(ies) provided in the following arg(s), could not be found: ids"
#                 }
#               ]
#             }} =
#              Absinthe.run(
#                """
#                  query (
#                    $ids: [ID]!
#                  ) {
#                   usersOrderPreserved(
#                     ids: $ids
#                    ){
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "ids" => ["1", "unknown", "2"]
#                }
#              )
#   end
# end

# describe "loading two arguments" do
#   test "success" do
#     assert {
#              :ok,
#              %{
#                data: %{
#                  "twoUsers" => [
#                    %{"id" => "2", "name" => "Bob"},
#                    %{"id" => "1", "name" => "Ally"}
#                  ]
#                }
#              }
#            } ===
#              Absinthe.run(
#                """
#                  query (
#                    $user1Id: ID!
#                    $user2Id: ID!
#                  ) {
#                   twoUsers (
#                     user1Id: $user1Id
#                     user2Id: $user2Id
#                    ) {
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "user1Id" => "2",
#                  "user2Id" => "1"
#                }
#              )
#   end

#   test "one not provided" do
#     assert {
#              :ok,
#              %{
#                data: %{
#                  "twoUsers" => [
#                    nil,
#                    %{"id" => "2", "name" => "Bob"}
#                  ]
#                }
#              }
#            } ===
#              Absinthe.run(
#                """
#                  query (
#                    $user2Id: ID!
#                  ) {
#                   twoUsers (
#                     user2Id: $user2Id
#                    ) {
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "user2Id" => "2"
#                }
#              )
#   end

#   test "none provided" do
#     assert {
#              :ok,
#              %{
#                data: %{
#                  "twoUsers" => [nil, nil]
#                }
#              }
#            } ===
#              Absinthe.run(
#                """
#                  query {
#                   twoUsers {
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema
#              )
#   end

#   test "error one not found" do
#     assert {
#              :ok,
#              %{
#                data: nil,
#                errors: [
#                  %{
#                    extensions: %{code: "NOT_FOUND"},
#                    message:
#                      "The entity(ies) provided in the following arg(s), could not be found: user2_id"
#                  }
#                ]
#              }
#            } =
#              Absinthe.run(
#                """
#                  query (
#                    $user1Id: ID!
#                    $user2Id: ID!
#                  ) {
#                   twoUsers (
#                     user1Id: $user1Id
#                     user2Id: $user2Id
#                    ) {
#                     id
#                     name
#                    }
#                  }
#                """,
#                TestSchema,
#                variables: %{
#                  "user1Id" => "1",
#                  "user2Id" => "unknown"
#                }
#              )
#   end
# end
