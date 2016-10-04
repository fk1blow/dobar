defmodule Dobar.Responder.Supervisor do
  use Supervisor

  @sup_name Dobar.Responder.Supervisor

  def start_link(opts) do
    # TODO do not register with a name
    Supervisor.start_link @sup_name, opts
    # Supervisor.start_link @sup_name, []
  end

  # def respond(sup, message) do
  def respond(pid, {message, interface}) do
    # TODO do not register with a name
    # TODO: pass the pid of the supervisor, directly through `respond` function
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
