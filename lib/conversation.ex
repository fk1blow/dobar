defmodule Dobar.Conversation do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Dobar.Conversation.Dialog, [:root_dialog, nil]),
    ]

    supervise children, strategy: :one_for_all
  end
end
