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

<img src="https://raw.githubusercontent.com/marick/ecto_test_data_builder/main/pics/reservation_schema.png" width="400px"/>

I claim that code is a better way to set up test data than other approaches. 

In addition to creating rows in database tables, the functions produce
a "repo cache", conventionally bound to `repo`, that contains a view into
the database that makes common testing operations simpler.

For example, it's straightforward to have the `repo` structure contain
top-level fields that point directly to important values. This allows
you to avoid the busywork of keeping track of database ids. Instead,
there's only one "source of truth" and you use that:

```elixir
# setup

repo = 
  ...
  |> animal("bossie", ...)
...

# The function under test

... VM.Animal.fetch(:one_for_edit, repo.bossie.id) ...
                                   ^^^^^^^^^^^^^^
```

That's surprisingly useful.

## More information

[Online documentation](https://hexdocs.pm/ecto_test_data_builder)

See [USE.md](./USE.md) for a description of using this package to
create a custom test-data builder.

## Installation

Add `ecto_test_data_builder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_test_data_builder, "~> 0.1.0"}
  ]
end
```
