defmodule Dobar.Conversation.Intention.MessageReceiver do
  @behaviour Dobar.Conversation.Intention.Capability

  @next_reply "who's the recipient of the message?"
  @halt_reason "cannot find the contact name/s in the provided intent!"

  alias Dobar.Model.Intent

  # TODO: generic shit - implement it inside a protocol or something
  def become_next(%Intent{} = intent) do
    unless intent.entities[:contact] do
      {:become_next, @next_reply}
    end
  end

  # TODO: generic shit - implement it inside a protocol or something
  def handle_expected(%Intent{} = old_intent, %Intent{} = new_intent) do
    if new_intent.entities[:contact] do
      found_entities = %{contact: new_intent.entities[:contact]}
      new_entities = Map.merge(old_intent.entities, found_entities)
      {:ok, Map.put(old_intent, :entities, new_entities)}
    else
      {:halt, @halt_reason}
    end
  end
end
