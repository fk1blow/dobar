defmodule Dobar.Intent do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(Dobar.Intent.Resolver, [])
    ]
    opts = [strategy: :one_for_one]
    supervise children, opts
  end
end
