defmodule AbsintheUtilsTest.Middleware.ArgLoaderTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Middleware.ArgLoader

  defmodule TestSchema do
    use Absinthe.Schema

    object :user do
      field(:id, :id)
      field(:name, :string)
    end

    query do
      field :user, :user do
        arg(:id, non_null(:id))

        middleware(
          ArgLoader,
          %{
            id: [
              new_name: :user,
              load_function: fn
                "123" ->
                  {
                    :ok,
                    %{
                      id: "123",
                      name: "Sample Name"
                    }
                  }

                "invalid" ->
                  {:ok, nil}
              end
            ]
          }
        )

        resolve(fn _, params, _ ->
          {:ok, params.user}
        end)
      end
    end
  end

  @query """
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
  """

  test "loading user by id" do
    assert {:ok,
            %{
              data: %{
                "user" => %{
                  "id" => "123",
                  "name" => "Sample Name"
                }
              }
            }} ===
             Absinthe.run(
               @query,
               TestSchema,
               variables: %{
                 "id" => "123"
               }
             )
  end

  test "user not found" do
    assert {:ok,
            %{
              errors: [
                %{
                  extensions: %{code: "NOT_FOUND"},
                  message: "The entities provided in the following ids, could not be found: id"
                }
              ]
            }} =
             Absinthe.run(
               @query,
               TestSchema,
               variables: %{
                 "id" => "invalid"
               }
             )
  end
end
