defmodule EctoTestDataBuilder.Repo do
  alias EctoTestDataBuilder.Schema, as: Schema

  @moduledoc """

  Functions for manipulating the repo cache.

  One can `load_fully/3` individual cache values, or groups of
  them. "Fully loaded" is application-defined, but typically means
  most or all of a schema's associations.

  One can also produce `shorthand/2` references to values by
  installing them as atom keys at the top level of the repo cache,
  allowing:

      ...Repo.get(repo.bossie.id)...
  """

  @doc """
  Fully load all values in a list of schemas, with "fully" determined by caller.

      load_fully(repo, [:animal, :procedure], loader)

  The result is a new repo, with the values within the schemas having
  been loaded from the persistent store. Typically, the values have
  had some or all of their associations loaded. 

  There are these variants:

      load_fully(repo, value_loader, schemas: [:animal, :procedure]        )
      load_fully(repo, value_loader, schema:   :animal                     )
      load_fully(repo, value_loader, schema:   :animal,  names: ["bossie"] )
      load_fully(repo, value_loader, schema:   :animal,  name:   "bossie"  )

  A `value_loader` is given two arguments. The first is a schema name; the
  second is a value from which a query key can be extracted. The loader
  most likely calls code like this:

           query =
             from a in Animal,
             where: a.id == ^current_id,
             preload: [:service_gaps, :species]
           Repo.one!(query)

  In many cases, it would be possible to use a `where a.id in [...]`
  query, but that would require the loader to keep track of which
  loaded value corresponds to which name/key.

  It is safe - a no-op - to refer to a schema that has never been created (and
  consequently contains no values. Referring to a nonexistent name raises an
  exception.

  If `shorthand/2` has been used, the shorthand values are also updated.
  """
  def load_fully(repo, loader, opts) do
    case Enum.into(opts, %{}) do
      %{schema: schema, names: names} ->
        load_for_names_within_schema(repo, schema, names, loader)
      %{schema: schema, name: name} ->
        load_for_names_within_schema(repo, schema, [name], loader)
      %{schema: schema} ->
        load_for_all_within_schema(repo, schema, loader)
      %{schemas: schemas} ->
        load_for_all_within_schemas(repo, schemas, loader)
    end
  end

  defp load_for_all_within_schemas(repo, schema_list, loader) do
    Enum.reduce(schema_list, repo, fn schema, acc ->
      load_for_all_within_schema(acc, schema, loader)
    end)
  end

  defp load_for_all_within_schema(repo, schema, loader) do
    names = Schema.names(repo, schema)
    load_for_names_within_schema(repo, schema, names, loader)
  end

  defp load_for_names_within_schema(repo, schema, names, loader) do
    values =
      for n <- names, do: requiring_existence(repo, schema, n, &(&1))
    new_values =
      for v <- values, do: loader.(schema, v)
    replacements =
      Enum.zip(names, new_values)

    repo
    |> Schema.replace(schema, replacements)
    |> replace_shorthand(schema, replacements)
  end

  @doc """
  Make particular names available in a `repo.name` format.

  This:

       repo = 
         put(:animal, "bossie", %Animal{id: 5})
         shorthand(schema: :animal)

  allows this:

       repo.bossie.id    # 5

  There are these variants:

      shorthand(repo, schemas: [:animal, :procedure]        )
      shorthand(repo, schema:   :animal                     )
      shorthand(repo, schema:   :animal,  names: ["bossie"] )
      shorthand(repo, schema:   :animal,  name:   "bossie"  )

  Names are downcased and any spaces are replaced with underscores, so this:

      shorthand(repo, schema:   :animal,  name:   "Bossie the Cow")

  ... is attached to the repo so that `repo.bossie_the_cow` retrieves the value.

  It is safe - a no-op - to refer to a schema that has never been created (and
  consequently contains no values. Referring to a nonexistent name raises an
  exception.
  """
  def shorthand(repo, opts) do
    case Enum.into(opts, %{}) do
      %{schema: schema, names: names} -> 
        shorthand_for_names_within_schema(repo, schema, names)
      %{schema: schema, name: name} ->
        shorthand_for_names_within_schema(repo, schema, [name])
      %{schema: schema} ->
        shorthand_for_all_within_schema(repo, schema)
      %{schemas: schemas} ->
        shorthand_for_all_within_schemas(repo, schemas)
    end
  end

  defp shorthand_for_all_within_schemas(repo, schema_list) do
    Enum.reduce(schema_list, repo, fn schema, acc ->
      shorthand_for_all_within_schema(acc, schema)
    end)
  end

  defp shorthand_for_all_within_schema(repo, schema) do
    names = Schema.names(repo, schema)
    shorthand_for_names_within_schema(repo, schema, names)
  end

  defp shorthand_for_names_within_schema(repo, schema, names) do
    Enum.reduce(names, repo, fn name, acc ->
      requiring_existence(repo, schema, name, fn value ->
        acc
        |> remember_shorthand({schema, name})
        |> install_shorthand({schema, name}, value)
       end)
    end)
  end

  defp requiring_existence(repo, schema, name, f) do
    case Schema.get(repo, schema, name) do
      nil ->
        raise "There is no `#{inspect name}` in schema `#{inspect schema}`"
      value ->
        f.(value)
    end
  end

  defp remember_shorthand(repo, {_, name} = key) do
    name_atom =
      name |> String.downcase |> String.replace(" ", "_") |> String.to_atom

    memory = Map.put(shorthands(repo), key, name_atom)
    Map.put(repo, :__shorthands__, memory)
  end

  defp install_shorthand(repo, schema_and_name, value) do
    case get_in(repo, [:__shorthands__, schema_and_name]) do
      nil ->
        repo
      name_atom -> 
        Map.put(repo, name_atom, value)
    end
  end

  defp replace_shorthand(repo, schema, name_value_pairs) do
    Enum.reduce(name_value_pairs, repo, fn {name, value}, acc ->
      install_shorthand(acc, {schema, name}, value)
    end)
  end

  defp shorthands(repo),
    do: Map.get(repo, :__shorthands__, %{})
end
