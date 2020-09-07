# README

This provides support code for writing Ecto test data builders that
are used like this:

```elixir
repo = 
  empty_repo()
  |> procedure("haltering", frequency: "twice per week")
  |> reservation_for(["bossie"], ["haltering"], date: @wed)
  |> reservation_for(["bossie"], ["haltering"], date: @mon)
```

That code constructs test data for a database
configuration like this:

<img src="/pics/reservation_schema.png" width="400px"/>

See [USE.md](./USE.md) for an example of building a test-data
builder using this package.
        
=======
I claim the code is a better way to set up test data than other approaches. 

In addition to creating rows in database tables, the functions produce a big map, conventionally bound to `repo`, that 
contains a view into the database that makes common testing operations simpler.

For example, it's straightforward to have the `repo` structure contain top-level fields that point directly to important values. This allows you to avoid the busywork of keeping track of database ids. Instead, there's only one "source of truth" and you use that:

```elixir
# setup

repo = 
  ...
  |> animal("bossie", ...)
  |> shorthand(schema: :animal)
...

# The function under test

... VM.Animal.fetch(:one_for_edit, repo.bossie.id) ...
                                   ^^^^^^^^^^^^^^
```

This is surprisingly useful.


>>>>>>> 388302ca096978f8be9c6d97546bf44cd8381f8c

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_test_data_builder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_test_data_builder, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_test_data_builder](https://hexdocs.pm/ecto_test_data_builder).

