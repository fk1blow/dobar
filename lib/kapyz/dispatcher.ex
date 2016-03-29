defmodule Dobar.Kapyz.Dispatcher do
  use GenServer

  alias Dobar.Kapyz.Error.NoIntentHandlerError
  alias Dobar.Kapyz.Error.InvalidIntentName

  @name __MODULE__

  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_) do
    {:ok, Map.new}
  end

  def register_capability(name, pid) do
    GenServer.cast(@name, {:register_capability, name, pid})
  end

  def evaluate_intent(intent) do
    GenServer.cast(@name, {:evaluate_intent, intent})
  end

  # callbacks
  #

  def handle_cast({:register_capability, name, pid}, handlers) do
    intent_handler = Map.put(%{}, name, pid)
    {:noreply, Map.merge(handlers, intent_handler)}
  end

  def handle_cast({:evaluate_intent, %Dobar.Models.Intent{} = intent}, handlers) do
    name = intent.name
    case intent.name do
      name when is_atom(name) ->
        call_intent_handler! intent.name, intent.entities, handlers
      name when is_binary(name) ->
        call_intent_handler! String.to_atom(intent.name), intent.entities, handlers
      _ -> raise InvalidIntentName
    end
    {:noreply, handlers}
  end

  def handle_cast({:evaluate_intent, {:error, error}}, handlers) do
    IO.puts "intent"
    {:noreply, handlers}
  end

  # private
  #

  defp call_intent_handler!(name, message, handlers) do
    case handlers[name] do
      nil -> raise NoIntentHandlerError
      pid -> if Process.alive?(pid),
        do: send(pid, {:handle_capability, message}),
        else: raise NoIntentHandlerError
    end
  end
end
