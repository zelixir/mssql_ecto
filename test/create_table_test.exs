defmodule MssqlEcto.CreateTableTest do
  use ExUnit.Case, async: true

  import Ecto.Migration, only: [table: 1, table: 2, references: 1, references: 2]

  alias MssqlEcto.Connection, as: SQL
  
  test "create table" do
    create = {:create, table(:posts),
              [{:add, :name, :string, [default: "Untitled", size: 20, null: false]},
               {:add, :price, :numeric, [precision: 8, scale: 2, default: {:fragment, "expr"}]},
               {:add, :on_hand, :integer, [default: 0, null: true]},
               {:add, :published_at, :"time without time zone", [null: true]},
               {:add, :is_active, :boolean, [default: true]}]}

    assert execute_ddl(create) == ["""
    CREATE TABLE "posts" ("name" nvarchar(20) DEFAULT 'Untitled' NOT NULL,
    "price" numeric(8,2) DEFAULT expr,
    "on_hand" bigint DEFAULT 0 NULL,
    "published_at" time without time zone NULL,
    "is_active" bit DEFAULT 1)
    """ |> remove_newlines]
  end

  test "create table with prefix" do
    create = {:create, table(:posts, prefix: :foo),
              [{:add, :category_0, references(:categories), []}]}

    assert execute_ddl(create) == ["""
    CREATE TABLE "foo"."posts"
    ("category_0" bigint CONSTRAINT "posts_category_0_fkey" REFERENCES "foo"."categories"("id"))
    """ |> remove_newlines]
  end

  test "create table with references" do
    create = {:create, table(:posts),
              [{:add, :id, :serial, [primary_key: true]},
               {:add, :category_0, references(:categories), []},
               {:add, :category_1, references(:categories, name: :foo_bar), []},
               {:add, :category_2, references(:categories, on_delete: :nothing), []},
               {:add, :category_3, references(:categories, on_delete: :delete_all), [null: false]},
               {:add, :category_4, references(:categories, on_delete: :nilify_all), []},
               {:add, :category_5, references(:categories, on_update: :nothing), []},
               {:add, :category_6, references(:categories, on_update: :update_all), [null: false]},
               {:add, :category_7, references(:categories, on_update: :nilify_all), []},
               {:add, :category_8, references(:categories, on_delete: :nilify_all, on_update: :update_all), [null: false]}]}

    assert execute_ddl(create) == ["""
    CREATE TABLE "posts" ("id" bigint identity(1,1),
    "category_0" bigint CONSTRAINT "posts_category_0_fkey" REFERENCES "categories"("id"),
    "category_1" bigint CONSTRAINT "foo_bar" REFERENCES "categories"("id"),
    "category_2" bigint CONSTRAINT "posts_category_2_fkey" REFERENCES "categories"("id"),
    "category_3" bigint NOT NULL CONSTRAINT "posts_category_3_fkey" REFERENCES "categories"("id") ON DELETE CASCADE,
    "category_4" bigint CONSTRAINT "posts_category_4_fkey" REFERENCES "categories"("id") ON DELETE SET NULL,
    "category_5" bigint CONSTRAINT "posts_category_5_fkey" REFERENCES "categories"("id"),
    "category_6" bigint NOT NULL CONSTRAINT "posts_category_6_fkey" REFERENCES "categories"("id") ON UPDATE CASCADE,
    "category_7" bigint CONSTRAINT "posts_category_7_fkey" REFERENCES "categories"("id") ON UPDATE SET NULL,
    "category_8" bigint NOT NULL CONSTRAINT "posts_category_8_fkey" REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY ("id"))
    """ |> remove_newlines]
  end

  test "create table with options" do
    create = {:create, table(:posts, [options: "WITH FOO=BAR"]),
              [{:add, :id, :serial, [primary_key: true]},
               {:add, :created_at, :naive_datetime, []}]}
    assert execute_ddl(create) ==
      [~s|CREATE TABLE "posts" ("id" bigint identity(1,1), "created_at" datetime2, PRIMARY KEY ("id")) WITH FOO=BAR|]
  end

  test "create table with composite key" do
    create = {:create, table(:posts),
              [{:add, :a, :integer, [primary_key: true]},
               {:add, :b, :integer, [primary_key: true]},
               {:add, :name, :string, []}]}

    assert execute_ddl(create) == ["""
    CREATE TABLE "posts" ("a" bigint, "b" bigint, "name" nvarchar(255), PRIMARY KEY ("a", "b"))
    """ |> remove_newlines]
  end

  defp execute_ddl(command) do
    command |> SQL.execute_ddl() |> Enum.map(&IO.iodata_to_binary/1)
  end
  defp remove_newlines(string) do
    string |> String.trim |> String.replace("\n", " ")
  end
end
