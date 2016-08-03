defmodule Dobar.Dialog.Router do
  defmacro __using__(_opts) do
    quote do
      import Dobar.Dialog.Router

      @dialogs []

      @before_compile Dobar.Dialog.Router
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def dialog(name) when is_atom(name) do
        get_dialog(name)
      end
      def dialog(name) when is_bitstring(name) do
        get_dialog(String.to_atom name)
      end

      def generic_dialog, do: Dobar.Dialog.GenericDialog

      defp get_dialog(name) do
        case @dialogs[name] do
          nil -> Dobar.Dialog.GenericDialog
          dialog -> dialog
        end
      end
    end
  end

  defmacro dialog(name, to: module) do
    quote do
      @dialogs [{unquote(name), unquote(module)} | @dialogs]
    end
  end
end
