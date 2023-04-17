defmodule AshGraphql.AttributeTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      Application.delete_env(:ash_graphql, AshGraphql.Test.Api)

      try do
        AshGraphql.TestHelpers.stop_ets()
      rescue
        _ ->
          :ok
      end
    end)
  end

  test ":uuid arguments are mapped to ID type" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "SimpleCreatePostInput") {
          inputFields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    author_id_field =
      data["__type"]["inputFields"]
      |> Enum.find(fn field -> field["name"] == "authorId" end)

    assert author_id_field["type"]["name"] == "ID"
  end

  test "atom attribute with one_of constraints has enums automatically generated" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "PostVisibility") {
          enumValues {
            name
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    assert data["__type"]
  end

  test "atom attribute with one_of constraints uses enum for inputs" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "CreatePostInput") {
          inputFields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    visibility_field =
      data["__type"]["inputFields"]
      |> Enum.find(fn field -> field["name"] == "visibility" end)

    assert visibility_field["type"]["kind"] == "ENUM"
  end

  @tag :wip
  test "map attribute with field constraints get their own type" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "MapTypes") {
          fields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)

    fields = data["__type"]["fields"]

    attributes_field =
      fields
      |> Enum.find(fn field -> field["name"] == "attributes" end)

    values_field =
      fields
      |> Enum.find(fn field -> field["name"] == "values" end)

    assert attributes_field == %{
             "name" => "attributes",
             "type" => %{
               "kind" => "NON_NULL",
               "name" => nil,
               "ofType" => %{"kind" => "OBJECT", "name" => "MapTypesAttributes"}
             }
           }

    assert values_field == %{
             "name" => "values",
             "type" => %{"kind" => "OBJECT", "name" => "ConstrainedMap", "ofType" => nil}
           }
  end

  @tag :wip
  test "map attribute with field constraints use input objects for inputs" do
    {:ok, %{data: data}} =
      """
      query {
        __type(name: "MapTypesAttributesInput") {
          inputFields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
      |> Absinthe.run(AshGraphql.Test.Schema)
      |> IO.inspect()

    foo_field =
      data["__type"]["inputFields"]
      |> Enum.find(fn field -> field["name"] == "foo" end)

    assert foo_field["type"]["kind"] == "SCALAR"
    assert foo_field["type"]["name"] == "String"

    bar_field =
      data["__type"]["inputFields"]
      |> Enum.find(fn field -> field["name"] == "bar" end)

    assert bar_field["type"]["kind"] == "SCALAR"
    assert bar_field["type"]["name"] == "Int"
  end
end
