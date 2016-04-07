defmodule Dobar.Conversation.Intention.MessageBody do
  @behaviour Dobar.Conversation.Intention.Capability

  @next_reply "what's the message you want to send?"
  @halt_reply "cannot find the message body in the provided reply!"

  alias Dobar.Model.Intent

   # TODO: generic shit - implement it inside a protocol or something
  def become_next(%Intent{} = intent) do
    unless intent.entities[:message_body] do
      {:become_next, @next_reply}
    end
  end

  # TODO: generic shit - implement it inside a protocol or something
  def handle_expected(%Intent{} = old_intent, %Intent{} = new_intent) do
    if new_intent.entities[:message_body] do
      found_entities = %{message_body: new_intent.entities[:message_body]}
      new_entities = Map.merge(old_intent.entities, found_entities)
      {:ok, Map.put(old_intent, :entities, new_entities)}
    else
      {:error, @halt_reason}
    end
  end
end
