defmodule Dobar.Conversation.Intention.MessageApp do
  @behaviour Dobar.Conversation.CapabilityBehaviour

  @next_reply "what's the application you would like to use?"
  @halt_reason "cannot find the application name in the provided reply!"

  alias Dobar.Model.Intent

  # TODO: generic shit - implement it inside a protocol or something
  def become_next(%Intent{} = intent) do
    unless intent.entities[:app_name] do
      {:become_next, @next_reply}
    end
  end

  # TODO: generic shit - implement it inside a protocol or something
  def handle_expected(%Intent{} = old_intent, %Intent{} = new_intent) do
    if new_intent.entities[:app_name] do
      found_entities = %{app_name: new_intent.entities[:app_name]}
      new_entities = Map.merge(old_intent.entities, found_entities)
      {:ok, Map.put(old_intent, :entities, new_entities)}
    else
      {:error, @halt_reason}
    end
  end
end
