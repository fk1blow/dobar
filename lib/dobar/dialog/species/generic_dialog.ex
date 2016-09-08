defmodule Dobar.Dialog.GenericDialog do
  use Dobar.Dialog.Species

  def handle_intent(intent, state), do: super(intent, state)
end
