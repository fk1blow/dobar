defmodule Dobar.Conversation do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(GenEvent, [[name: :intention_events]]),
      worker(Dobar.Conversation.Manager, []),
    ]

    supervise children, strategy: :one_for_all
  end
end
