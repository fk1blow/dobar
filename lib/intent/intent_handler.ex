defmodule Dobar.Intent.IntentHandler do
  use GenEvent

  def register_with_manager(pid) do
    GenEvent.add_handler pid, __MODULE__, nil
  end
end
