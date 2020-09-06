defmodule EctoTestDataBuilder.Repo do

  alias EctoTestDataBuilder.Schema, as: Schema

  @doc """
  Reload all values in a list of schemas, with thoroughness determined by caller.

      reload(repo, [:animal, :procedure], reloader)

  The result is a new repo, with the values within the schemas having
  been reloaded from the persistent store.

  There are these variants:

      reload(repo, value_reloader, schemas: [:animal, :procedure]        )
      reload(repo, value_reloader, schema:   :animal                     )
      reload(repo, value_reloader, schema:   :animal,  names: ["bossie"] )
      reload(repo, value_reloader, schema:   :animal,  name:   "bossie"  )

  A `value_reloader` is given two arguments. The first is a schema name; the
  second is a value from which a query key can be extracted. The value reloader
  most likely calls code like this:

           query =
             from a in Animal,
             where: a.id == ^current_id,
             preload: [:service_gaps, :species]
           Repo.one!(query)

  That's not so efficient, but it relieves the reloader of the
  responsibility of indicating which reloaded value corresponds to
  which name/key.

  It is safe - a no-op - to refer to a schema that has never been created (and
  consequently contains no values. Referring to a nonexistent name raises an
  exception.

  If `shorthand/2` has been used, the shorthand values are also updated.
  """
  def reload(repo, reloader, opts) do
    case Enum.into(opts, %{}) do
      %{schema: schema, names: names} ->
        reload_for_names_within_schema(repo, schema, names, reloader)
      %{schema: schema, name: name} ->
        reload_for_names_within_schema(repo, schema, [name], reloader)
      %{schema: schema} ->
        reload_for_all_within_schema(repo, schema, reloader)
      %{schemas: schemas} ->
        reload_for_all_within_schemas(repo, schemas, reloader)
    end
  end

  defp reload_for_all_within_schemas(repo, schema_list, reloader) do
    Enum.reduce(schema_list, repo, fn schema, acc ->
      reload_for_all_within_schema(acc, schema, reloader)
    end)
  end

  defp reload_for_all_within_schema(repo, schema, reloader) do
    names = Schema.names(repo, schema)
    reload_for_names_within_schema(repo, schema, names, reloader)
  end

  defp reload_for_names_within_schema(repo, schema, names, reloader) do
    values =
      for n <- names, do: requiring_existence(repo, schema, n, &(&1))
    new_values =
      for v <- values, do: reloader.(schema, v)
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
    name_atom = name |> String.downcase |> String.to_atom

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
