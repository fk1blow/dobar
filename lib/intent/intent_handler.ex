defmodule Dobar.Intent.IntentHandler do
  use GenEvent

  def register_with_manager(pid) do
    IO.puts "manager: #{inspect pid}"

    IO.puts "process info: #{Process.whereis(pid)}"

    r = GenEvent.add_handler pid, __MODULE__, nil
    # GenEvent.add_handler Dobar.Intent.EventManager, Dobar.Intent.IntentHandler, nil
    # IO.inspect r
    :ok
  end
end
