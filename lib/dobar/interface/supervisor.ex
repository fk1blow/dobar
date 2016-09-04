defmodule Dobar.Interface.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link __MODULE__,
      [event_manager: opts[:event_manager]],
      name: __MODULE__
  end

  def init(args) do
    children = [
      worker(Dobar.Interface,
        [[event_manager: args[:event_manager], interface_conf: Dialog.Interface]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
