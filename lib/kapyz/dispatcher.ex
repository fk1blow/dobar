defmodule Dobar.Kapyz.Dispatcher do
  use GenServer

  alias Dobar.Kapyz.Error.NoIntentHandlerError
  alias Dobar.Kapyz.Error.InvalidIntentName

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
    case name do
      name when is_atom(name) ->
        call_intent_handler! name, data, state
      name when is_binary(name) ->
        call_intent_handler! String.to_atom(name), data, state
      _ -> raise InvalidIntentName
    end
    {:noreply, state}
  end

  defp call_intent_handler!(name, message, handlers) do
    case handlers[name] do
      nil -> raise NoIntentHandlerError
      pid -> if Process.alive?(pid),
        do: send(pid, {:handle_capability, message}),
        else: raise NoIntentHandlerError
    end
  end
end
