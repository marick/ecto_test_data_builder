# EctoTestDataBuilder

This provides support code for writing Ecto test data builders that
are used like this:

```elixir
repo = 
  empty_repo()
  |> procedure("haltering", frequency: "twice per week")
  |> reservation_for(["bossie"], ["haltering"], date: @wed)
  |> reservation_for(["bossie"], ["haltering"], date: @mon)
```

That code constructs in-database test data for a database
configuration like this:

<img src="/pics/reservation_schema.png" width="600px"/>



        

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

