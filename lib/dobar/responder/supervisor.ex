defmodule Dobar.Responder.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link __MODULE__, opts
  end

  def respond(pid, {message, interface}) do
    pid
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} ->
      GenServer.cast pid, {message, interface}
    end)
  end

  def init(args) do
    responders = args[:responders]
    children = case responders do
      nil     -> []
      [h | t] ->
        responders
        |> Enum.filter(fn {module, opts} -> Code.ensure_loaded?(module) end)
        |> Enum.map(fn {name, opts} -> worker(name, [args]) end)
    end
    supervise(children, strategy: :one_for_one)
  end
end
