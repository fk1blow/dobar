defmodule Dobar.Intent.IntentHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to an intent.
  An intent is an expression that was evaluated and its intention was detected.

  Features:
    - accepts events for text input that need intention resolving
    - accepts notifications for when a intention has been determined
    - accepts events for when an intent....?
  """

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
