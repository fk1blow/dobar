defmodule Dobar.Kapyz.Dispatcher do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, Map.new}
  end

  def register_intent(name, pid) do
    GenServer.cast(__MODULE__, {:register_intent, name, pid})
  end

  def process_intent(intent) do
    GenServer.cast(__MODULE__, {:process_intent, intent})
  end

  def handle_cast({:register_intent, name, pid}, state) do
    intent_handler = Map.put(%{}, name, pid)
    {:noreply, Map.merge(state, intent_handler)}
  end

  def handle_cast({:process_intent, %{name: name, data: data}}, state) do
    case state[String.to_atom(name)] do
      nil -> IO.puts ".......... plm......"
      pid -> send pid, :test
    end

    {:noreply, state}
  end
end
