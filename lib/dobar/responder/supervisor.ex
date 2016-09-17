defmodule Dobar.Responder.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  # GenServer.cast Dobar.Xapp.GenericResponder, {:complete, %{dataz: "sassssssssssssssg"}}
  def respond(about, data) do
    IO.puts "should take each responder and call it with `about` and `data`"
  end

  def init(_) do
    supervise(responders, strategy: :one_for_one)
  end

  defp responders do
    Application.get_env(:dobar, Dobar.Conversation)
    |> Keyword.get(:responders)
    |> Enum.map(fn {name, opts} -> worker(name, [opts]) end)
  end
end
