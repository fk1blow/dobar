defmodule Dobar.Interface do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(GenEvent, [[name: :interface_events]]),
      worker(Dobar.Interface.Controller, [])
    ]

    supervise children, strategy: :one_for_one
  end
end
