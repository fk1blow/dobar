defmodule Dobar.Dialog do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      # start the `intent_events` event manager
      worker(GenEvent, [[name: :intent_events]]),
      # start the intent resolver gen server
      worker(Dobar.Intent.Resolver, [])
    ]
    supervise children, strategy: :one_for_one
  end
end
