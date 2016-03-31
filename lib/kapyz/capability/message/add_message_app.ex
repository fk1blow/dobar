defmodule Dobar.Kapyz.Capability.AddMessageApp do
  use Dobar.Kapyz.Capability, name: :add_message_app

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(old_intent, %Intent{} = new_intent) do
    entities = Map.merge(old_intent.entities, new_intent.entities)
    intent = Map.put old_intent, :entities, entities
    capability = %Capability{context: %{state: "message_body"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end
end
