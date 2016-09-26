defmodule Dobar.Responder.Supervisor do
  use Supervisor

  @sup_name Dobar.Responder.Supervisor

  def start_link(opts) do
    Supervisor.start_link @sup_name, opts, name: @sup_name
  end

  def respond(message) do
    @sup_name
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.cast pid, message end)
  end

  def init(args) do
    children = responders |> Enum.map(fn {name, opts} -> worker(name, [args]) end)
    supervise(children, strategy: :one_for_one)
  end

  defp responders do
    :dobar |> Application.get_env(Dobar.Conversation) |> Keyword.get(:responders)
  end
end
