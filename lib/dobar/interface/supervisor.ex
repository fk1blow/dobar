defmodule Dobar.Interface.Supervisor do
  use Supervisor

  def start_link(conf) do
    Supervisor.start_link __MODULE__, conf
  end

  def process_input(sup, message) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn spec -> send(elem(spec, 1), message) end)
  end

  def init(args) do
    children = [
      worker(Dobar.Interface, [args])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
