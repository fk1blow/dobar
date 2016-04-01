defmodule Dobar.Kapyz.Capability.AddMessageContact do
  use Dobar.Kapyz.Capability, name: :add_message_contact

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(old_intent, %Intent{entities: %{email: _, app_name: _}} = new_intent) do
    entities = Map.merge(old_intent.entities, new_intent.entities)
    intent = Map.put old_intent, :entities, entities
    capability = %Capability{context: %{state: "message_body"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{contact: _, app_name: _}} = new_intent) do
    entities = Map.merge(old_intent.entities, new_intent.entities)
    intent = Map.put old_intent, :entities, entities
    capability = %Capability{context: %{state: "message_body"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{email: _}} = new_intent) do
    entities = Map.merge(old_intent.entities, new_intent.entities)
    intent = Map.put old_intent, :entities, entities
    capability = %Capability{context: %{state: "message_application"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{contact: _}} = new_intent) do
    entities = Map.merge(old_intent.entities, new_intent.entities)
    intent = Map.put old_intent, :entities, entities
    capability = %Capability{context: %{state: "message_application"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end
end
