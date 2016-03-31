defmodule Dobar.Kapyz.Capability.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Dobar.Kapyz.Capability.AccountInfo, []),
      worker(Dobar.Kapyz.Capability.SearchFiles, []),
      worker(Dobar.Kapyz.Capability.SendMessage, []),
      worker(Dobar.Kapyz.Capability.AddMessageContact, []),
    ]
    supervise children, strategy: :one_for_one
  end
end
