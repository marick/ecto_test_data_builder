defmodule EctoTestDataBuilder.RepoTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias EctoTestDataBuilder, as: B

  @start %{}
  @fake_animal %{id: "bossie_id", association: :unloaded}

  describe "shorthand" do 
    test "fetching" do
      repo =
        @start
        |> B.Schema.put(:animal, "bossie", "bossie")
        |> B.Schema.put(:animal, "jake", "jake")
        |> B.Schema.put(:procedure, "haltering", "haltering")
      
      gives = fn opts, expected ->
        new_repo = B.Repo.shorthand(repo, opts)
        [Map.get(new_repo, :bossie), Map.get(new_repo, :jake)]
        |> Enum.reject(&(&1 == nil))
        |> assert_equal(expected)
      end
      
      [schemas: [:animal]                   ] |> gives.(["bossie", "jake"])
      [schema:   :animal                    ] |> gives.(["bossie", "jake"])
      [schema:   :animal, names: ["bossie"] ] |> gives.(["bossie"])
      [schema:   :animal, name:   "jake"    ] |> gives.(["jake"])
    end

    test "the schema can be missing" do
      pass = fn opts, repo ->
        assert B.Repo.shorthand(repo, opts) == repo
      end

      # These are so empty they don't even have a __schemas__ key.
      [schemas: [:irrelevant]] |> pass.(@start)
      [schema:   :irrelevant ] |> pass.(@start)
      
      # This forces the __schemas__ key to be present.
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")
      [schemas: [:missing_schema]] |> pass.(repo)
      [schema:   :missing_schema ] |> pass.(repo)
    end

    test "the name must exist in the schema" do
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")

      assert_raise RuntimeError, fn -> 
        B.Repo.shorthand(repo, schema: :animal, name: "missing")
      end
    end

    test "string names are downcased and underscored" do
      repo = 
        @start
        |> B.Schema.put(:animal, "Bossie the Cow", "bossie data")
        |> B.Repo.shorthand(schema: :animal)

      assert repo.bossie_the_cow == "bossie data"
    end      
  end
  
  describe "loading completely" do

    defp loader _schema, value do 
      %{value | association: %{note: "association loaded"}}
    end
      
    test "normal loading" do
      repo = B.Schema.put(@start, :animal, "bossie", @fake_animal)

      pass = fn opts ->
        repo
        |> B.Repo.load_fully(&loader/2, opts)
        |> B.Schema.get(:animal, "bossie")
        |> assert_field(association: %{note: "association loaded"})
      end
      
      [schemas: [:animal]]                  |> pass.()
      [schema:   :animal ]                  |> pass.()
      [schema:   :animal, name: "bossie"  ] |> pass.()
      [schema:   :animal, names: ["bossie"] ] |> pass.()
    end

    test "the schema can be missing" do
      # It happens to create an empty one, which is harmless
      pass = fn opts, repo, schema ->
        new_repo = B.Repo.load_fully(repo, &loader/2, opts)
        assert B.Schema.names(new_repo, schema) == []
      end

      # These are so empty they don't even have a __schemas__ key.
      [schemas: [:irrelevant]] |> pass.(@start, :irrelevant)
      [schema:   :irrelevant ] |> pass.(@start, :irrelevant)
      
      # This forces the __schemas__ key to be present.
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")
      [schemas: [:missing_schema]] |> pass.(repo, :missing_schema)
      [schema:   :missing_schema ] |> pass.(repo, :missing_schema)
    end
    
    test "the name must exist in the schema" do
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")

      assert_raise RuntimeError, fn -> 
        B.Repo.load_fully(repo, &loader/2, schema: :animal, name: "missing")
      end
    end

    test "loading re-establishes shorthand" do
      repo = 
        B.Schema.put(@start, :animal, "bossie", @fake_animal)
        |> B.Repo.shorthand(schema: :animal)
        |> B.Repo.load_fully(&loader/2, schema: :animal)

      repo.bossie.association
      |> assert_field(note: "association loaded")
    end
  end
end
