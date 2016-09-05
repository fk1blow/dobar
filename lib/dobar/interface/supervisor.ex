defmodule Dobar.Interface.Supervisor do
  use Supervisor

  def start_link(opts),
    do: Supervisor.start_link __MODULE__, opts, name: __MODULE__

  def init(args) do
    children = [
      worker(Dobar.Interface,
        [[event_manager: args[:event_manager], interface_conf: args[:interface_conf]]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
