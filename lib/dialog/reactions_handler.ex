defmodule Dobar.Dialog.ReactionsHandler do
  use GenEvent

  alias Dobar.Model.Reaction

  def handle_event({:completed, %Reaction{} = reaction}, _state) do
    IO.puts "received a reaction from the Dialog system"
    {:ok, nil}
  end
end
