defmodule AbsintheUtilsTest.Middleware.DeprecatedArgsTest do
  use ExUnit.Case, async: true

  alias AbsintheUtils.Middleware.DeprecatedArgs

  # TODO: add tests for non_null: true.
  # Also, how to prevent is_required: false and non_null: true together?

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :query_with_deprecated_required_args, non_null(:string) do
        arg(:old_arg, :string, deprecate: "Use `newParam` instead.")
        arg(:new_arg, :string)

        middleware(
          DeprecatedArgs,
          %{
            legacy_arg_identifier: :old_arg,
            new_arg_identifier: :new_arg,
            is_required: true
          }
        )

        resolve(fn _, params, _ ->
          {:ok, params.new_arg}
        end)
      end

      field :query_with_deprecated_required_non_null_args, non_null(:string) do
        arg(:old_arg, :string, deprecate: "Use `newParam` instead.")
        arg(:new_arg, :string)

        middleware(
          DeprecatedArgs,
          %{
            legacy_arg_identifier: :old_arg,
            new_arg_identifier: :new_arg,
            is_required: true,
            non_null: true
          }
        )

        resolve(fn _, params, _ ->
          {:ok, params.new_arg}
        end)
      end

      field :query_with_deprecated_optional_args, :string do
        arg(:old_arg, :string, deprecate: "Use `newParam` instead.")
        arg(:new_arg, :string)

        middleware(
          DeprecatedArgs,
          %{
            legacy_arg_identifier: :old_arg,
            new_arg_identifier: :new_arg,
            is_required: false
          }
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :new_arg)}
        end)
      end
    end
  end

  describe "required argument" do
    test "passing new argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedRequiredArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                   ) {
                     queryWithDeprecatedRequiredArgs(
                      newArg: $newArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "sample value"
                 }
               )
    end

    test "passing old argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedRequiredArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $oldArg: String
                   ) {
                     queryWithDeprecatedRequiredArgs(
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "oldArg" => "sample value"
                 }
               )
    end

    test "passing both legacy and new arguments" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION"},
                     message: "Arguments oldArg and newArg cannot be passed together"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                     $oldArg: String
                   ) {
                     queryWithDeprecatedRequiredArgs(
                      newArg: $newArg
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "ignored",
                   "oldArg" => "ignored"
                 }
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION"},
                     message:
                       "Exactly one of the following arguments must be provided: oldArg, newArg"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithDeprecatedRequiredArgs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "required non null argument" do
    test "passing new argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedRequiredNonNullArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                   ) {
                     queryWithDeprecatedRequiredNonNullArgs(
                      newArg: $newArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "sample value"
                 }
               )
    end

    test "passing old argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedRequiredNonNullArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $oldArg: String
                   ) {
                     queryWithDeprecatedRequiredNonNullArgs(
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "oldArg" => "sample value"
                 }
               )
    end

    test "passing both legacy and new arguments" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION"},
                     message: "Arguments oldArg and newArg cannot be passed together"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                     $oldArg: String
                   ) {
                     queryWithDeprecatedRequiredNonNullArgs(
                      newArg: $newArg
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "ignored",
                   "oldArg" => "ignored"
                 }
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION"},
                     message:
                       "Exactly one of the following arguments must be provided: oldArg, newArg"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithDeprecatedRequiredNonNullArgs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "optional argument" do
    test "passing new argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedOptionalArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                   ) {
                     queryWithDeprecatedOptionalArgs(
                      newArg: $newArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "sample value"
                 }
               )
    end

    test "passing old argument" do
      assert {:ok,
              %{
                data: %{
                  "queryWithDeprecatedOptionalArgs" => "sample value"
                }
              }} ===
               Absinthe.run(
                 """
                   query (
                     $oldArg: String
                   ) {
                     queryWithDeprecatedOptionalArgs(
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "oldArg" => "sample value"
                 }
               )
    end

    test "passing both legacy and new arguments" do
      assert {
               :ok,
               %{
                 data: %{"queryWithDeprecatedOptionalArgs" => nil},
                 errors: [
                   %{
                     extensions: %{code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION"},
                     message: "Arguments oldArg and newArg cannot be passed together"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query (
                     $newArg: String
                     $oldArg: String
                   ) {
                     queryWithDeprecatedOptionalArgs(
                      newArg: $newArg
                      oldArg: $oldArg
                     )
                   }
                 """,
                 TestSchema,
                 variables: %{
                   "newArg" => "ignored",
                   "oldArg" => "ignored"
                 }
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: %{"queryWithDeprecatedOptionalArgs" => nil}
               }
             } ===
               Absinthe.run(
                 """
                   query {
                     queryWithDeprecatedOptionalArgs
                   }
                 """,
                 TestSchema
               )
    end
  end
end
