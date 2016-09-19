defmodule Dobar.Responder.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link __MODULE__, opts, name: __MODULE__
  end

  def respond(about, data) do
    Dobar.Responder.Supervisor
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.cast pid, {about, data} end)
  end

  def init(args) do
    children = responders |> Enum.map(fn {name, opts} -> worker(name, [args]) end)
    supervise(children, strategy: :one_for_one)
  end

  defp responders do
    Application.get_env(:dobar, Dobar.Conversation) |> Keyword.get(:responders)
  end
end
