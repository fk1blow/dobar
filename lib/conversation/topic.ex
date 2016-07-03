defmodule Dobar.Conversation.Topic do
  alias Dobar.Model.Intent

  def start_topic(nil), do: {:ended, nil}
  def start_topic(slot), do: {:ok, slot}

  def end_topic(%Intent{entities: entities}, slot) do
    slot_key = String.to_atom(elem(slot, 1).entity)
    cond do
      Map.has_key?(entities, slot_key) == true ->
        {:ok, entities, slot_key}
      true ->
        {:error, "no match for key #{inspect slot_key}", slot_key}
    end
  end
end
