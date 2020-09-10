defmodule EctoTestDataBuilder.Macro do

  @moduledoc """
  Macros useful for writing a test-data builder.
  """

  @doc """
  Given a function that produces a single repo value, produce a function
  that creates many.

      B.Macro.make_plural_builder(:procedures, from: :procedure)

  The new function (`procedures`) is passed a `repo` and a list of
  names.

      procedures(["haltering", "pregnancy checking"])

  `procedures` ensures that all of the names exist in the `repo` by passing
  each of them to the old function (`procedure`).

  The new function is used to quicky and easily create values that have
  nothing special about them other than that they exist and can be retrieved
  by name. 
  """

  defmacro make_plural_builder(plural, from_keyword)
  defmacro make_plural_builder(plural, from: singular) do
    quote do
      def unquote(plural)(repo, names) do
        Enum.reduce(names, repo, fn name, acc ->
          apply __MODULE__, unquote(singular), [acc, name, []]
        end)
      end
    end
  end
end
