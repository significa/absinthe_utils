defmodule AbsintheUtilsTest.Middleware.MutuallyExclusiveInputsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AbsintheUtils.Middleware.MutuallyExclusiveInputs

  defmodule TestSchema do
    @moduledoc false

    use Absinthe.Schema

    query do
      # Simple args - required
      field :query_with_required_mutually_exclusive_args, non_null(:string) do
        arg(:arg_one, :string)
        arg(:arg_two, :string)

        middleware(
          MutuallyExclusiveInputs,
          fields: [:arg_one, :arg_two],
          is_required: true
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :arg_one) || Map.get(params, :arg_two) || "none"}
        end)
      end

      # Simple args - optional
      field :query_with_optional_mutually_exclusive_args, :string do
        arg(:arg_one, :string)
        arg(:arg_two, :string)

        middleware(
          MutuallyExclusiveInputs,
          fields: [:arg_one, :arg_two],
          is_required: false
        )

        resolve(fn _, params, _ ->
          {:ok, Map.get(params, :arg_one) || Map.get(params, :arg_two)}
        end)
      end

      # Three args - required
      field :query_with_three_required_mutually_exclusive_args, non_null(:string) do
        arg(:arg_one, :string)
        arg(:arg_two, :string)
        arg(:arg_three, :string)

        middleware(
          MutuallyExclusiveInputs,
          fields: [:arg_one, :arg_two, :arg_three],
          is_required: true
        )

        resolve(fn _, params, _ ->
          {:ok,
           Map.get(params, :arg_one) || Map.get(params, :arg_two) || Map.get(params, :arg_three) ||
             "none"}
        end)
      end

      # Nested input object fields - required
      field :query_with_required_nested_mutually_exclusive_inputs, non_null(:string) do
        arg(:input, :example_input)

        middleware(
          MutuallyExclusiveInputs,
          fields: [
            [:input, :field_one],
            [:input, :field_two],
            [:input, :field_three]
          ],
          is_required: true
        )

        resolve(fn _, params, _ ->
          input = Map.get(params, :input, %{})

          {
            :ok,
            Map.get(input, :field_one) || Map.get(input, :field_two) ||
              Map.get(input, :field_three) || "none"
          }
        end)
      end

      # Nested input object fields - optional
      field :query_with_nested_optional_mutually_exclusive_inputs, :string do
        arg(:input, :example_input)

        middleware(
          MutuallyExclusiveInputs,
          fields: [
            [:input, :field_one],
            [:input, :field_two]
          ],
          is_required: false
        )

        resolve(fn _, params, _ ->
          input = Map.get(params, :input, %{})
          {:ok, Map.get(input, :field_one) || Map.get(input, :field_two)}
        end)
      end

      field :query_with_complex_nested_and_non_nested_optional_mutually_exclusive_inputs,
            :string do
        arg(:input, :example_input)
        arg(:outside_field, :string)

        middleware(
          MutuallyExclusiveInputs,
          fields: [
            [:input, :field_one],
            [:outside_field]
          ],
          is_required: false
        )

        resolve(fn _, params, _ ->
          input = Map.get(params, :input, %{})

          {
            :ok,
            Map.get(input, :field_one) || Map.get(input, :field_two) ||
              Map.get(input, :field_three) ||
              Map.get(params, :outside_field)
          }
        end)
      end
    end

    input_object :example_input do
      field(:field_one, :string)
      field(:field_two, :string)
      field(:field_three, :string)
    end
  end

  describe "required mutually exclusive args - simple args" do
    test "passing first argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithRequiredMutuallyExclusiveArgs" => "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredMutuallyExclusiveArgs(
                      argOne: "value_one"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing second argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithRequiredMutuallyExclusiveArgs" => "value_two"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredMutuallyExclusiveArgs(
                      argTwo: "value_two"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing both arguments" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two]]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: argOne, argTwo"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredMutuallyExclusiveArgs(
                      argOne: "ignored"
                      argTwo: "ignored"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two]]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: argOne, argTwo"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredMutuallyExclusiveArgs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "optional mutually exclusive args - simple args" do
    test "passing first argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithOptionalMutuallyExclusiveArgs" => "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithOptionalMutuallyExclusiveArgs(
                      argOne: "value_one"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing second argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithOptionalMutuallyExclusiveArgs" => "value_two"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithOptionalMutuallyExclusiveArgs(
                      argTwo: "value_two"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing both arguments" do
      assert {
               :ok,
               %{
                 data: %{"queryWithOptionalMutuallyExclusiveArgs" => nil},
                 errors: [
                   %{
                     extensions: %{
                       code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two]]
                     },
                     message: "Only one of the arguments argOne, argTwo can be provided at a time"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithOptionalMutuallyExclusiveArgs(
                      argOne: "ignored"
                      argTwo: "ignored"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: %{"queryWithOptionalMutuallyExclusiveArgs" => nil}
               }
             } ===
               Absinthe.run(
                 """
                   query {
                     queryWithOptionalMutuallyExclusiveArgs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "three required mutually exclusive args" do
    test "passing first argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithThreeRequiredMutuallyExclusiveArgs" => "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs(
                      argOne: "value_one"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing second argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithThreeRequiredMutuallyExclusiveArgs" => "value_two"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs(
                      argTwo: "value_two"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing third argument only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithThreeRequiredMutuallyExclusiveArgs" => "value_three"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs(
                      argThree: "value_three"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing two arguments" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two], [:arg_three]]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: argOne, argTwo, argThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs(
                      argOne: "ignored"
                      argTwo: "ignored"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing all three arguments" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two], [:arg_three]]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: argOne, argTwo, argThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs(
                      argOne: "ignored"
                      argTwo: "ignored"
                      argThree: "ignored"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:arg_one], [:arg_two], [:arg_three]]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: argOne, argTwo, argThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithThreeRequiredMutuallyExclusiveArgs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "nested input object fields - required" do
    test "passing first field only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithRequiredNestedMutuallyExclusiveInputs" => "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: { fieldOne: "value_one" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing second field only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithRequiredNestedMutuallyExclusiveInputs" => "value_two"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: { fieldTwo: "value_two" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing third field only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithRequiredNestedMutuallyExclusiveInputs" => "value_three"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: { fieldThree: "value_three" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing two fields" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [
                         [:input, :field_one],
                         [:input, :field_two],
                         [:input, :field_three]
                       ]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: input.fieldOne, input.fieldTwo, input.fieldThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: { fieldOne: "ignored", fieldTwo: "ignored" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing all three fields" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [
                         [:input, :field_one],
                         [:input, :field_two],
                         [:input, :field_three]
                       ]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: input.fieldOne, input.fieldTwo, input.fieldThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: { fieldOne: "ignored", fieldTwo: "ignored", fieldThree: "ignored" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any field" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [
                         [:input, :field_one],
                         [:input, :field_two],
                         [:input, :field_three]
                       ]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: input.fieldOne, input.fieldTwo, input.fieldThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs(
                      input: {}
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing input argument at all" do
      assert {
               :ok,
               %{
                 data: nil,
                 errors: [
                   %{
                     extensions: %{
                       code: "REQUIRED_MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [
                         [:input, :field_one],
                         [:input, :field_two],
                         [:input, :field_three]
                       ]
                     },
                     message:
                       "Exactly one of the following arguments must be provided: input.fieldOne, input.fieldTwo, input.fieldThree"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithRequiredNestedMutuallyExclusiveInputs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "nested input object fields - optional" do
    test "passing first field only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithNestedOptionalMutuallyExclusiveInputs" => "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithNestedOptionalMutuallyExclusiveInputs(
                      input: { fieldOne: "value_one" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing second field only" do
      assert {:ok,
              %{
                data: %{
                  "queryWithNestedOptionalMutuallyExclusiveInputs" => "value_two"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithNestedOptionalMutuallyExclusiveInputs(
                      input: { fieldTwo: "value_two" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing both fields" do
      assert {
               :ok,
               %{
                 data: %{"queryWithNestedOptionalMutuallyExclusiveInputs" => nil},
                 errors: [
                   %{
                     extensions: %{
                       code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:input, :field_one], [:input, :field_two]]
                     },
                     message:
                       "Only one of the arguments input.fieldOne, input.fieldTwo can be provided at a time"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithNestedOptionalMutuallyExclusiveInputs(
                      input: { fieldOne: "ignored", fieldTwo: "ignored" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any field" do
      assert {
               :ok,
               %{
                 data: %{"queryWithNestedOptionalMutuallyExclusiveInputs" => nil}
               }
             } ===
               Absinthe.run(
                 """
                   query {
                     queryWithNestedOptionalMutuallyExclusiveInputs(
                      input: {}
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing input argument at all" do
      assert {
               :ok,
               %{
                 data: %{"queryWithNestedOptionalMutuallyExclusiveInputs" => nil}
               }
             } ===
               Absinthe.run(
                 """
                   query {
                     queryWithNestedOptionalMutuallyExclusiveInputs
                   }
                 """,
                 TestSchema
               )
    end
  end

  describe "complex nested and non-nested optional mutually exclusive inputs" do
    test "passing only input.field_one" do
      assert {:ok,
              %{
                data: %{
                  "queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs" =>
                    "value_one"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs(
                       input: { fieldOne: "value_one" }
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing only sample_arg" do
      assert {:ok,
              %{
                data: %{
                  "queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs" =>
                    "sample_value"
                }
              }} ===
               Absinthe.run(
                 """
                   query {
                     queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs(
                       outside_field: "sample_value"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "passing both input.field_one and sample_arg (should fail)" do
      assert {
               :ok,
               %{
                 data: %{
                   "queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs" => nil
                 },
                 errors: [
                   %{
                     extensions: %{
                       code: "MUTUALLY_EXCLUSIVE_ARG_VIOLATION_ERROR",
                       field_paths: [[:input, :field_one], [:outside_field]]
                     },
                     message:
                       "Only one of the arguments input.fieldOne, outsideField can be provided at a time"
                   }
                 ]
               }
             } =
               Absinthe.run(
                 """
                   query {
                     queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs(
                       input: { fieldOne: "value_one" }
                       outside_field: "sample_value"
                     )
                   }
                 """,
                 TestSchema
               )
    end

    test "not passing any argument" do
      assert {
               :ok,
               %{
                 data: %{
                   "queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs" => nil
                 }
               }
             } ===
               Absinthe.run(
                 """
                   query {
                     queryWithComplexNestedAndNonNestedOptionalMutuallyExclusiveInputs
                   }
                 """,
                 TestSchema
               )
    end
  end
end
