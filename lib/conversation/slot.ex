defmodule Dobar.Conversation.Slot do
  alias Dobar.Model.Intent
  alias Dobar.Model.Dialog

  @doc """
  It filters out the slots that don't have the `:entity` key
  """
  def only_entities(slots) do
    Enum.filter(slots, fn(x) -> is_nil(elem(x, 1)[:entity]) == false end)
    |> Enum.map(fn(x) -> {elem(x, 0), Enum.into(elem(x, 1), %{})} end)
  end

  @doc """
  It sorts a list of slots, based on the slot `:prio` key
  """
  def slots_by_priority(slots) do
    Enum.sort(slots, fn(a, b) -> elem(a, 1)[:prio] > elem(b, 1)[:prio] end)
  end

  @doc """
  It filters out the slots that are already prefilled, matching the entity slots
  available to the slots contained inside the %Dialog struct
  """
  def slots_not_filled(%Dialog{slots: slots}, entity_slots) do
    Enum.filter(entity_slots, fn(x) ->
      key = String.to_atom elem(x, 1).entity
      Map.has_key?(slots, key) == false
    end)
  end

  @doc """
  It transforms the entities coming from the %Intent, to a map having the structure:
  `%{contact: %{name: :contact, value: "Mona"}}`
  """
  def from_intent(%Intent{entities: entities} = intent) do
    Map.keys(entities) |> List.foldl(%{}, fn(x, acc) ->
      Map.put(acc, x, %{name: x, value: hd(entities[x]).value})
    end)
  end

  def first_by_priority(entity_slots) do
    slots_by_priority(entity_slots) |> List.first
  end
end
