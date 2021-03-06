defmodule EctoTestDataBuilder do
  @moduledoc """
  Support code for the creation of builders that (1) create persistent state,
  typically in an Ecto Repo, and (2) produce a map that describes that
  persistent state in a form that's convenient for tests.

  That map is called the "repo cache" in this documentation and is
  conventionally bound to `repo` in code.
  
  The main part of the structure looks like this:

        %{__schemas__: 
           %{animal: %{"bossie" => %Animal{name: "bossie", ...},
                       "daisy" => %Animal{name: "daisy", ...}},
             procedure: ...
            },
         ...}

  Individual animals can be gotten from the schema with `EctoTestDataBuilder.Schema.get/3`, but
  there's a shorthand notation that's usually better. You can choose for
  the repo cache to have top-level keys that are the names of leaf values:
  
        %{__schemas__:
           %{animal: %{"bossie" => %Animal{name: "bossie", ...}...}...},
          bossie: %Animal{name: "bossie",...}, 
          ...
         }

  That means one variable gives convenient access to everything
  that's on disk at the start of the test. Most especially, it makes it
  easy to get at ids:
  
        |> VM.Animal.lower_changeset(repo.bossie.id, @institution)
                                     ^^^^^^^^^^^^^^
        |> assert_change(span: Datespan.inclusive_up(repo.bossie.span.first))
                                                     ^^^^^^^^^^^^^^^^^^^^^^

  Typically the values in the repo cache are "fully loaded", which usually
  means that `Ecto.Schema.has_many/3` and `Ecto.Schema.belongs_to/3`
  associations are loaded.  The meaning of "fully loaded" can be
  decided, schema by schema, by the implemention of the builder that
  uses this code.

  """
end
