defmodule Dobar.Conversation.Topic do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, nil}
  end

  def start_topic(slot) do
    GenServer.call __MODULE__, {:start_topic, slot}
  end

  def end_topic(answer_entities) do
    GenServer.call __MODULE__, {:end_topic, answer_entities}
  end

  def handle_call({:start_topic, nil}, _from, nil) do
    {:reply, {:ended, "slots already filled"}, nil}
  end
  def handle_call({:start_topic, slot}, _from, _) do
    {:reply, {:ok, slot}, slot}
  end

  def handle_call({:end_topic, answer}, _from, state) do
    slot_key = String.to_atom(elem(state, 1).entity)
    cond do
      Map.has_key?(answer, slot_key) == true ->
        {:reply, {:ok, answer, slot_key}, nil}
      true ->
        {:reply, {:error, "no match for key #{inspect slot_key}", slot_key}, state}
    end
  end
end
