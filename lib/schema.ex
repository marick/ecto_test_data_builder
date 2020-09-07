defmodule EctoTestDataBuilder.Schema do
  import DeepMerge

  @moduledoc """
  Functions for working with schemas inside a repo.

  "Repo" here is the slang for the in-memory structure that mimics 
  """
  
  @doc """
  Put a value into a repo structure.
  
         put(repo, :animal, "bossie", %Animal{...})
         
  If the first key (`:animal`) is missing, it is created.
  
  If the second key (`"bossie"`) is already present, it is overwritten.
  
  See also `create_if_needed/4`
  """
  
  def put(repo, schema, name, value) do
    deep_merge(repo, %{__schemas__: %{schema => %{name => value}}})
  end
  
  @doc """
  Replace some schema values within the repo.
  
  The final argument is an enumeration of `{name, value}` pairs.
  All of the values are installed, as with `put/4`, under the corresponding
  name. 
  """
  def replace(repo, schema, pairs) do
    deep_merge(repo, %{__schemas__: %{schema => Map.new(pairs)}})
  end
  
  @doc """
  Get a value from a repo structure.
  
      repo
      |> get(:animals, "bossie")
  
  The first key typically represents a Schema (it may in fact be the
  schema's name), the second an individual instance of the schema.
  
  Return `nil` if either key does not exist.

  Test code usually uses the results of `EctoTestDataBuilder.Repo.shorthand/2`
  in preference to this function.
  """
  def get(repo, schema, name) do
    schemas(repo)[schema][name]
  end
  
  @doc """
  Like `put/4`, but does nothing if the value already exists.
  
  This supports the creation of functions used as shown:
  
      empty_repo()
      |> procedure("haltering", frequency: "twice per week")
      |> reservation_for(["bossie"], ["haltering"], date: @mon)
  
  `reservation_for` is written so that it calls these two functions for
  the above data:

      animal("bossie")
      procedure("haltering")

  Those in turn call `create_if_needed`. In the case of "bossie", an
  animal is created. Nothing is guaranteed about that animal but
  that it exists and has the name bossie.
  
  In the case of "haltering", nothing is done because the procedure
  already exists. 
  """
  def create_if_needed(repo, schema, name, creator) do 
    case get(repo, schema, name) do
      nil -> put(repo, schema, name, creator.())
      _ -> repo
    end
  end
  
  @doc """
  Return all the names (keys) for the given schema.
  
  Returns [] if the schema does not exist.
  """
  def names(repo, schema) do
    Map.get(schemas(repo), schema, %{}) |> Map.keys
  end
  
  defp schemas(repo), do: Map.get(repo, :__schemas__, %{})
end
