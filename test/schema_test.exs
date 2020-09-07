defmodule EctoTestDataBuilder.SchemaTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias EctoTestDataBuilder, as: B

  @start %{}
  @sample ~D[2002-02-02]

  describe "get" do
    test "returns nil for a starting repo" do
      assert B.Schema.get(@start, Sample, "name") == nil
    end

    test "returns nil when schema hasn't been added" do
      @start
      |> B.Schema.put(:dates, "name", @sample)
      |> B.Schema.get(:some_other_schema, "name")
      |> assert_equal(nil)
    end

    test "typical returns" do
      repo = B.Schema.put(@start, :schema, "name", @sample)

      assert B.Schema.get(repo, :schema, "name") == @sample
      assert B.Schema.get(repo, :schema, "missing") == nil
    end
  end

  describe "creational code" do 
    test "put overwrites" do
      @start
      |> B.Schema.put(:dates, "name", "first value")
      |> B.Schema.put(:dates, "name", "second value")
      |> B.Schema.get(:dates, "name")
      |> assert_equal("second value")
    end
    
    test "create_if_needed does not overwrite" do
      repo =
        @start
        |> B.Schema.create_if_needed(:animal, "bossie", fn -> "bossie value" end)

      repo 
      |> B.Schema.get(:animal, "bossie")
      |> assert_equal("bossie value")
      
      repo
      |> B.Schema.create_if_needed(:animal, "bossie", fn -> "IGNORED" end)
      |> B.Schema.get(:animal, "bossie")
      |> assert_equal("bossie value")
    end
  end

  test "names" do
    repo = 
      B.Schema.put(@start, :animal, "bossie", "bossie content")

    assert B.Schema.names(repo, :animal) == ["bossie"]
    assert B.Schema.names(repo, :nothing) == []
  end    
end
