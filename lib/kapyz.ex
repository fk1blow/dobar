defmodule Dobar.Kapyz do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Dobar.Kapyz.Dispatcher, []),
      supervisor(Dobar.Kapyz.Capability.Supervisor, [])
    ]
    supervise children, strategy: :one_for_all
  end
end
