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
    interface_module = args[:interface_module]
    children = case responders do
      nil     -> []
      [_ | _] ->
        responders
        |> Enum.filter(fn {module, _} -> Code.ensure_loaded?(module) end)
        |> Enum.map(fn {name, opts} ->
          worker(name, Keyword.put(opts, :interface_module, interface_module))
        end)
    end
    supervise(children, strategy: :one_for_one)
  end
end
