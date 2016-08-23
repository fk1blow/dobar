defmodule Dobar.Dialog.Species.Router do
  defmacro __using__(_opts) do
    quote do
      import Dobar.Dialog.Species.Router
      @dialog_species []
      @before_compile Dobar.Dialog.Species.Router
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def specie(name) when is_bitstring(name), do: name |> String.to_existing_atom |> specie
      def specie(name) when is_atom(name), do: name |> specie
      def specie(name) do
        case @dialog_species[name] do
          nil -> Dobar.Dialog.GenericDialog
          specie -> specie
        end
      end
    end
  end

  defmacro specie(name, to: module),
    do: quote do: @dialog_species [{unquote(name), unquote(module)} | @dialog_species]
end
