defmodule EctoTestDataBuilder.MixProject do
  use Mix.Project

  @github "https://github.com/marick/ecto_test_data_builder"
  @version "0.1.0"

  def project do
    [
      description: """
      Code that uses Ecto needs to be tested. Such tests need
      the database to be populated. It pays to write a test data
      builder for that purpose. This package makes writing that
      builder easier. 
      """,

      app: :ecto_test_data_builder,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Ecto Test Data Builder",
      source_url: @github,
      docs: [
        main: "EctoTestDataBuilder",
        extras: ["CHANGELOG.md"],
      ],
      
      package: [
        contributors: ["marick@exampler.com"],
        maintainers: ["marick@exampler.com"],
        licenses: ["Unlicense"],
        links: %{
          "GitHub" => @github
        },
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:deep_merge, "~> 1.0"},
      {:flow_assertions, "~> 0.4", only: :test},
    ]
  end
end
