defmodule Dobar.Intent.IntentHandler do
  use GenEvent

  def register_with_manager(pid) do
    IO.puts "xxxxxxx"
    r = GenEvent.add_handler pid, __MODULE__, nil
    IO.inspect r
    :ok
  end
end
