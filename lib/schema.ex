defmodule EctoTestDataBuilder.Schema do
  import DeepMerge

  @moduledoc """
  Functions for working with individual values inside a repo cache.

  This includes putting values, optionally putting values, fetching values,
  and so on. These functions all refer to values that are within a particular
  schema, where "schema" is typically an atom like `:animal` that corresponds
  to an `Ecto.Schema`. (It may also be the `Ecto.Schema` name itself - like
  `Crit.Schemas.Animal` - depending on what you want from the code that uses
  these functions. See [USE.md](USE.md).)
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
      |> get(:animal, "bossie")
  
  Returns `nil` if either argument doesn't exist in the `repo`. (That
  is, if there is no schema called `:animal`, or if `:animal` exists
  but has no key `"bossie"` within it.)

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

      repo
      |> animal("bossie")
      |> procedure("haltering")

  Those in turn call `create_if_needed`. In the case of `"bossie"`, an
  animal is created. Nothing is guaranteed about that animal but
  that it exists and has the name `"bossie"`.
  
  In the case of `"haltering"`, nothing is done because the procedure
  already exists. 
  """
  def create_if_needed(repo, schema, name, creator) do 
    case get(repo, schema, name) do
      nil -> put(repo, schema, name, creator.())
      _ -> repo
    end
  end
  
  @doc """
  Return all the names for the given schema.
  
  Returns [] if the schema does not exist.
  """
  def names(repo, schema) do
    Map.get(schemas(repo), schema, %{}) |> Map.keys
  end
  
  defp schemas(repo), do: Map.get(repo, :__schemas__, %{})

  @doc """
  Override defaults, but complain about non-default keys.

      combine_opts([a: 5555], %{a: 1, b: 2})   # %{a: 5555, b: 2}
      combine_opts([a: 5555], a: 1, b: 2)      # %{a: 5555, b: 2}
      combine_opts([c: 5555], %{a: 1, b: 2})   # "Unrecognized options: [:c]"

  Note that the return value is a map.

  """

  @spec combine_opts(keyword(), keyword() | map()) :: map()
  def combine_opts(given_options, defaults) when is_list(defaults),
    do: combine_opts(given_options, Enum.into(defaults, %{}))
    
  def combine_opts(given_options, defaults) do
    given_keys   = given_options |> Keyword.keys |> MapSet.new
    default_keys = defaults      |>     Map.keys |> MapSet.new
    
    case MapSet.difference(given_keys, default_keys) |> Enum.into([]) do
      [] -> 
        Enum.into(given_options, defaults)
      extras ->
        raise("Unrecognized options: #{inspect extras}")
    end
  end
end
